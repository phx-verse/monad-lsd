import winston from 'winston';
import 'winston-daily-rotate-file';

var log_transport = new winston.transports.DailyRotateFile({
    level: 'info',
    filename: './logs/proxy-%DATE%.log',
    datePattern: 'YYYY-MM-DD',
    zippedArchive: true,
    maxSize: '1000m',
    maxFiles: '3d'
});

var error_transport = new winston.transports.DailyRotateFile({
    level: 'error',
    filename: './logs/error-%DATE%.log',
    datePattern: 'YYYY-MM-DD',
    zippedArchive: true,
    maxSize: '100m',
    maxFiles: '7d'
});

const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.printf(({ timestamp, level, message }) => `${timestamp} ${level}: ${message}`)
    ),
    transports: [
        new winston.transports.Console(),
        log_transport,
        error_transport,
    ]
});

export default logger;