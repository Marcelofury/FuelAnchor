import express, { Request, Response } from 'express';
import swaggerUi from 'swagger-ui-express';
import YAML from 'yamljs';
import path from 'path';

const router = express.Router();

// Load OpenAPI specification
const swaggerDocument = YAML.load(path.join(__dirname, '../../docs/openapi.yaml'));

// Swagger UI options
const options = {
  explorer: true,
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'FuelAnchor API Documentation',
};

// Serve Swagger UI
router.use('/', swaggerUi.serve);
router.get('/', swaggerUi.setup(swaggerDocument, options));

// Export raw OpenAPI spec as JSON
router.get('/openapi.json', (req: Request, res: Response) => {
  res.json(swaggerDocument);
});

export default router;
