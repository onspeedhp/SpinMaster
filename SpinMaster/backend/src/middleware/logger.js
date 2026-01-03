// Request logging middleware
export const requestLogger = (req, res, next) => {
  const start = Date.now();
  
  // Log request
  console.log(`\n📥 ${req.method} ${req.path}`);
  if (Object.keys(req.query).length > 0) {
    console.log(`   Query:`, req.query);
  }
  if (req.body && Object.keys(req.body).length > 0) {
    console.log(`   Body:`, req.body);
  }
  if (req.headers.authorization) {
    console.log(`   Auth: ${req.headers.authorization.substring(0, 20)}...`);
  }

  // Capture response
  const originalSend = res.send;
  res.send = function(data) {
    const duration = Date.now() - start;
    console.log(`📤 ${res.statusCode} ${req.method} ${req.path} - ${duration}ms`);
    originalSend.call(this, data);
  };

  next();
};
