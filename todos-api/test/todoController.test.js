const TodoController = require('../todoController');

describe('TodoController', () => {
  let controller;
  let mockTracer;
  let mockRedisClient;
  let mockLogChannel;

  beforeEach(() => {
    mockTracer = {
      scoped: jest.fn((fn) => fn()),
      id: { traceId: 'test-trace-id' }
    };
    mockRedisClient = {
      publish: jest.fn()
    };
    mockLogChannel = 'test_channel';
    
    controller = new TodoController({
      tracer: mockTracer,
      redisClient: mockRedisClient,
      logChannel: mockLogChannel
    });
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('list', () => {
    it('should return todos for a user', () => {
      const mockReq = {
        user: { username: 'testuser' }
      };
      const mockRes = {
        json: jest.fn()
      };

      controller.list(mockReq, mockRes);

      expect(mockRes.json).toHaveBeenCalled();
      const todos = mockRes.json.mock.calls[0][0];
      expect(typeof todos).toBe('object');
    });

    it('should return default todos for new user', () => {
      const mockReq = {
        user: { username: 'newuser' }
      };
      const mockRes = {
        json: jest.fn()
      };

      controller.list(mockReq, mockRes);

      expect(mockRes.json).toHaveBeenCalled();
      const todos = mockRes.json.mock.calls[0][0];
      expect(Object.keys(todos)).toHaveLength(3);
      expect(todos['1']).toHaveProperty('id', 1);
      expect(todos['1']).toHaveProperty('content', 'Create new todo');
    });
  });

  describe('create', () => {
    it('should create a new todo', () => {
      const mockReq = {
        user: { username: 'testuser' },
        body: { content: 'Test todo' }
      };
      const mockRes = {
        json: jest.fn()
      };

      controller.create(mockReq, mockRes);

      expect(mockRes.json).toHaveBeenCalled();
      const todo = mockRes.json.mock.calls[0][0];
      expect(todo).toHaveProperty('content', 'Test todo');
      expect(todo).toHaveProperty('id');
    });

    it('should log create operation', () => {
      const mockReq = {
        user: { username: 'testuser' },
        body: { content: 'Test todo' }
      };
      const mockRes = {
        json: jest.fn()
      };

      controller.create(mockReq, mockRes);

      expect(mockTracer.scoped).toHaveBeenCalled();
      expect(mockRedisClient.publish).toHaveBeenCalledWith(
        mockLogChannel,
        expect.stringContaining('"opName":"CREATE"')
      );
    });
  });

  describe('delete', () => {
    it('should delete a todo', () => {
      const mockReq = {
        user: { username: 'testuser' },
        params: { taskId: '1' }
      };
      const mockRes = {
        status: jest.fn().mockReturnThis(),
        send: jest.fn()
      };

      controller.delete(mockReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(204);
      expect(mockRes.send).toHaveBeenCalled();
    });

    it('should log delete operation', () => {
      const mockReq = {
        user: { username: 'testuser' },
        params: { taskId: '1' }
      };
      const mockRes = {
        status: jest.fn().mockReturnThis(),
        send: jest.fn()
      };

      controller.delete(mockReq, mockRes);

      expect(mockTracer.scoped).toHaveBeenCalled();
      expect(mockRedisClient.publish).toHaveBeenCalledWith(
        mockLogChannel,
        expect.stringContaining('"opName":"DELETE"')
      );
    });
  });

  describe('_getTodoData', () => {
    it('should return default data for new user', () => {
      const data = controller._getTodoData('newuser');
      
      expect(data).toHaveProperty('items');
      expect(data).toHaveProperty('lastInsertedID');
      expect(data.lastInsertedID).toBe(3);
      expect(Object.keys(data.items)).toHaveLength(3);
    });

    it('should return cached data for existing user', () => {
      const userID = 'testuser';
      const testData = { items: {}, lastInsertedID: 5 };
      
      controller._setTodoData(userID, testData);
      const data = controller._getTodoData(userID);
      
      expect(data).toEqual(testData);
    });
  });

  describe('_setTodoData', () => {
    it('should store data in cache', () => {
      const userID = 'testuser';
      const testData = { items: {}, lastInsertedID: 1 };
      
      controller._setTodoData(userID, testData);
      const retrievedData = controller._getTodoData(userID);
      
      expect(retrievedData).toEqual(testData);
    });
  });
});
