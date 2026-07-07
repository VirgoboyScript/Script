const express = require('express');
const app = express();
app.get('/script', (req, res) => {
    if (req.headers['user-agent'] && req.headers['user-agent'].includes('Roblox')) {
        res.send("print('Script Berhasil Dijalankan')"); // Masukkan script obfuscate Anda di sini
    } else {
        res.status(404).send("Error 404");
    }
});
app.listen(process.env.PORT || 3000);
