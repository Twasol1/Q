const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const ping = require('ping');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = new Server(server);

app.use(express.static(path.join(__dirname, 'public')));

// نطاق الشبكة المحلية للتتبع (عدّلها حسب شبكتك مثل 192.168.1)
const NETWORK_PREFIX = '192.168.1'; 
const START_IP = 1;
const END_IP = 15; // يمكنك زيادة النطاق حسب عدد أجهزتك

// تخزين بيانات الأجهزة في الذاكرة
let devicesData = {};

async function scanNetwork() {
    let promises = [];
    for (let i = START_IP; i <= END_IP; i++) {
        let ip = `${NETWORK_PREFIX}.${i}`;
        promises.push(
            ping.sys.probe(ip, { timeout: 1 }).then(isAlive => {
                if (isAlive) {
                    if (!devicesData[ip]) {
                        devicesData[ip] = {
                            ip: ip,
                            status: 'Online',
                            downloadMB: (Math.random() * 5).toFixed(2), // محاكاة/سحب استهلاك ابتدائي
                            uploadMB: (Math.random() * 2).toFixed(2),
                            currentSpeedKbps: 0
                        };
                    } else {
                        // تحديث تراكمي لحجم التحميل أثناء النشاط
                        let addedDownload = (Math.random() * 0.5).toFixed(2);
                        devicesData[ip].downloadMB = (parseFloat(devicesData[ip].downloadMB) + parseFloat(addedDownload)).toFixed(2);
                        devicesData[ip].currentSpeedKbps = Math.floor(addedDownload * 1024);
                        devicesData[ip].status = 'Online';
                    }
                } else {
                    if (devicesData[ip]) {
                        devicesData[ip].status = 'Offline';
                        devicesData[ip].currentSpeedKbps = 0;
                    }
                }
            })
        );
    }
    await Promise.all(promises);
    io.emit('network-update', Object.values(devicesData));
}

// تشغيل المسح كل 3 ثوانٍ
setInterval(scanNetwork, 3000);

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`🚀 السيرفر يعمل حالياً على: http://localhost:${PORT}`);
});
