import fs from 'fs';
import path from 'path';
import { google } from 'googleapis';
import dotenv from 'dotenv';
import puppeteer from 'puppeteer';
import lighthouse from 'lighthouse';
import { URL } from 'url';

dotenv.config();

const lhciTempDir = path.join(process.cwd(), 'lighthouse-report');
if (!fs.existsSync(lhciTempDir)) {
    fs.mkdirSync(lhciTempDir);
}

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

    oAuth2Client.setCredentials({
        access_token: GOOGLE_ACCESS_TOKEN,
        refresh_token: GOOGLE_REFRESH_TOKEN,
        scope: GOOGLE_SCOPE,
        token_type: GOOGLE_TOKEN_TYPE,
        expiry_date: GOOGLE_EXPIRY_DATE
    });

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
        .sort((a, b) => b.time - a.time)
        .slice(0, 2);

    const urls = [];

    for (const fileInfo of htmlReports) {
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

async function runAudit(url) {
    const browser = await puppeteer.launch({
        executablePath: '/usr/bin/chromium',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    const { port } = new URL(browser.wsEndpoint());

    const result = await lighthouse(url, {
        port,
        output: 'html',
        onlyCategories: ['performance', 'accessibility', 'best-practices', 'seo'],
        formFactor: "desktop",
        screenEmulation: {
            "mobile": false,
            "width": 1360,
            "height": 1020,
            "deviceScaleFactor": 1,
            "disabled": false
        }

    });

    const reportHtml = result.report;
    const filename = `lighthouse-${Date.now()}.html`;
    const filePath = path.join(lhciTempDir, filename);
    fs.writeFileSync(filePath, reportHtml);

    console.log(`📄 Reporte generado: ${filePath}`);
    await browser.close();
}

export async function runLighthouse() {
    try {
        const urlsToAudit = [
            "https://www.chedraui.com.mx/supermercado?workspace=betaplpload",
            "https://www.chedraui.com.mx/supermercado?workspace=currentmaster"
        ];

        console.log('📊 Ejecutando auditorías Lighthouse...');
        for (const url of urlsToAudit) {
            await runAudit(url);
        }

        console.log("🔐 Cargando credenciales...");
        const auth = await loadCredentials();

        console.log("📤 Subiendo reportes a Google Drive...");
        const urls = await uploadToDrive(auth);

        const logFilePath = path.join(process.cwd(), 'lhci-report-log.txt');
        const timestamp = new Date().toISOString();

        urls.forEach(url => {
            const logEntry = `${timestamp} - ${url}\n`;
            fs.appendFileSync(logFilePath, logEntry);
        });

        console.log('✅ Reportes subidos y log actualizado');
        return { urls };
    } catch (error) {
        console.error('❌ Error en runLighthouse:', error.message);
        throw error;
    }
}
