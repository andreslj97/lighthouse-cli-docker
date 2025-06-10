import { useState } from 'react';

export default function RunLighthousePage() {
  const [loading, setLoading] = useState(false);
  const [urls, setUrls] = useState([]);
  const [error, setError] = useState(null);

  const handleClick = async () => {
    setLoading(true);
    setError(null);
    setUrls([]);

    try {
      const res = await fetch('/api/run');
      const data = await res.json();
      if (res.ok) {
        setUrls(data.urls || []);
      } else {
        throw new Error(data.error || 'Error desconocido');
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ padding: 20, fontFamily: 'Arial' }}>
      <h1>📊 Ejecutar Lighthouse Report</h1>
      <button onClick={handleClick} disabled={loading}>
        {loading ? 'Ejecutando...' : 'Ejecutar'}
      </button>

      {error && <p style={{ color: 'red' }}>❌ Error: {error}</p>}

      {urls.length > 0 && (
        <div>
          <h2>✅ Reportes subidos:</h2>
          <ul>
            {urls.map((url, i) => (
              <li key={i}>
                <a href={url} target="_blank" rel="noopener noreferrer">
                  Ver reporte {i + 1}
                </a>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
