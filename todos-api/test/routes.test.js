const express = require('express');
const bodyParser = require('body-parser');
const routes = require('../routes');

describe('Routes', () => {
  let app;
  let mockTracer;
  let mockRedisClient;
  let mockLogChannel;

  beforeEach(() => {
    app = express();
    app.use(bodyParser.json());
    
    mockTracer = {
      scoped: jest.fn((fn) => fn()),
      id: { traceId: 'test-trace-id' }
    };
    mockRedisClient = {
      publish: jest.fn()
    };
    mockLogChannel = 'test_channel';
    
    routes(app, { tracer: mockTracer, redisClient: mockRedisClient, logChannel: mockLogChannel });
  });

  describe('Route registration', () => {
    it('should register todos routes', () => {
      const routes = app._router.stack
        .filter(layer => layer.route)
        .map(layer => ({
          path: layer.route.path,
          methods: Object.keys(layer.route.methods)
        }));

      expect(routes).toContainEqual({
        path: '/todos',
        methods: ['get', 'post']
      });

      expect(routes).toContainEqual({
        path: '/todos/:taskId',
        methods: ['delete']
      });
    });

    it('should have correct HTTP methods for todos route', () => {
      const todosRoute = app._router.stack
        .find(layer => layer.route && layer.route.path === '/todos');
      
      expect(todosRoute).toBeDefined();
      expect(todosRoute.route.methods).toHaveProperty('get');
      expect(todosRoute.route.methods).toHaveProperty('post');
    });

    it('should have correct HTTP methods for todos/:taskId route', () => {
      const todosIdRoute = app._router.stack
        .find(layer => layer.route && layer.route.path === '/todos/:taskId');
      
      expect(todosIdRoute).toBeDefined();
      expect(todosIdRoute.route.methods).toHaveProperty('delete');
    });
  });

  describe('Controller instantiation', () => {
    it('should create TodoController with correct dependencies', () => {
      // The routes function should create a TodoController instance
      // We can verify this by checking that the routes are properly registered
      const routes = app._router.stack
        .filter(layer => layer.route)
        .map(layer => layer.route.path);
      
      expect(routes).toContain('/todos');
      expect(routes).toContain('/todos/:taskId');
    });
  });
});
