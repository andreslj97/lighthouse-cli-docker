import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import { google } from 'googleapis';
import dotenv from 'dotenv';

dotenv.config();

const lhciTempDir = path.join(process.cwd(), '.lighthouseci');

const {
    GOOGLE_CLIENT_ID,
    GOOGLE_CLIENT_SECRET,
    GOOGLE_REDIRECT_URI,
    GOOGLE_ACCESS_TOKEN,
    GOOGLE_REFRESH_TOKEN,
    GOOGLE_SCOPE,
    GOOGLE_TOKEN_TYPE,
    GOOGLE_EXPIRY_DATE
} = process.env;

async function loadCredentials() {
    const oAuth2Client = new google.auth.OAuth2(
        GOOGLE_CLIENT_ID,
        GOOGLE_CLIENT_SECRET,
        GOOGLE_REDIRECT_URI
    );

    const googleToken = {
        "access_token": GOOGLE_ACCESS_TOKEN,
        "refresh_token": GOOGLE_REFRESH_TOKEN,
        "scope": GOOGLE_SCOPE,
        "token_type": GOOGLE_TOKEN_TYPE,
        "expiry_date": GOOGLE_EXPIRY_DATE
    }

    oAuth2Client.setCredentials(googleToken);

    return oAuth2Client;
}

async function uploadToDrive(auth) {
    const drive = google.drive({ version: 'v3', auth });

    const htmlReports = fs.readdirSync(lhciTempDir)
        .filter(file => file.endsWith('.html'))
        .map(file => ({
            name: file,
            time: fs.statSync(path.join(lhciTempDir, file)).mtime.getTime(),
        }))
        .sort((a, b) => b.time - a.time);

    if (htmlReports.length < 1) {
        throw new Error('No se encontró ningún archivo HTML de reporte en ' + lhciTempDir);
    }

    const filesToUpload = htmlReports.slice(0, 2); // Subir los dos más recientes
    const urls = [];

    for (const fileInfo of filesToUpload) {
        const reportPath = path.join(lhciTempDir, fileInfo.name);

        const fileMetadata = {
            name: `lighthouse-${fileInfo.name}`,
        };

        const media = {
            mimeType: 'text/html',
            body: fs.createReadStream(reportPath),
        };

        const file = await drive.files.create({
            resource: fileMetadata,
            media: media,
            fields: 'id',
        });

        await drive.permissions.create({
            fileId: file.data.id,
            requestBody: {
                role: 'reader',
                type: 'anyone',
            },
        });

        const url = `https://drive.google.com/file/d/${file.data.id}/view`;
        console.log(`✅ Reporte subido: ${fileInfo.name} → ${url}`);
        urls.push(url);
    }

    return urls;
}

export async function runLighthouse() {

    const {
        GOOGLE_CLIENT_ID,
        GOOGLE_CLIENT_SECRET,
        GOOGLE_REDIRECT_URI,
        GOOGLE_ACCESS_TOKEN
    } = process.env;

    try {
        if (!GOOGLE_CLIENT_ID || !GOOGLE_CLIENT_SECRET || !GOOGLE_REDIRECT_URI || !GOOGLE_ACCESS_TOKEN) {
            throw new Error('Faltan variables de entorno para la autenticación con Google.');
        }

        console.log('📊 Ejecutando Lighthouse CI...');

        execSync(`npx lhci collect --config=server/lighthouserc.json`, { stdio: 'inherit' });

        console.log("🪪 Cargar credenciales...");

        const auth = await loadCredentials();
        console.log("🪪 Cargar archivos...");
        const urls = await uploadToDrive(auth);

        console.log('✅ Reportes subidos a Google Drive:', urls);

        const logFilePath = path.join(process.cwd(), 'lhci-report-log.txt');
        const timestamp = new Date().toISOString();

        urls.forEach(url => {
            const logEntry = `${timestamp} - ${url}\n`;
            fs.appendFileSync(logFilePath, logEntry);
        });

        return { url: urls };
    } catch (error) {
        console.error('❌ Error en runLighthouse:', error.message);
        throw error;
    }
}
