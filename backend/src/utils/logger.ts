import winston from 'winston';
import { config } from '../config/environment';

const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.printf(({ level, message, timestamp, stack }) => {
    return stack
      ? `${timestamp} [${level.toUpperCase()}]: ${message}\n${stack}`
      : `${timestamp} [${level.toUpperCase()}]: ${message}`;
  })
);

const jsonFormat = winston.format.combine(
  winston.format.timestamp(),
  winston.format.errors({ stack: true }),
  winston.format.json()
);

export const logger = winston.createLogger({
  level: config.logLevel,
  format: config.nodeEnv === 'production' ? jsonFormat : logFormat,
  defaultMeta: { service: 'fuelanchor-api' },
  transports: [
    new winston.transports.Console({
      format: config.nodeEnv === 'production' 
        ? jsonFormat 
        : winston.format.combine(winston.format.colorize(), logFormat),
    }),
    new winston.transports.File({ 
      filename: 'logs/error.log', 
      level: 'error',
      maxsize: 5242880, // 5MB
      maxFiles: 5,
    }),
    new winston.transports.File({ 
      filename: 'logs/combined.log',
      maxsize: 5242880,
      maxFiles: 5,
    }),
  ],
});

// Stream for Morgan HTTP logger
export const stream = {
  write: (message: string) => {
    logger.info(message.trim());
  },
};

export default logger;
