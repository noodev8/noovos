/*
=======================================================================================================================================
Middleware: auth
=======================================================================================================================================
Purpose: Verifies JWT tokens for protected routes
=======================================================================================================================================
*/

const jwt = require('jsonwebtoken');

// Middleware to verify JWT token
const verifyToken = (req, res, next) => {
    try {
        // Get the authorization header
        const authHeader = req.headers.authorization;
        
        // Check if authorization header exists
        if (!authHeader) {
            return res.status(401).json({
                return_code: "UNAUTHORIZED",
                message: "No authorization token provided"
            });
        }
        
        // Extract the token (Bearer token format)
        const token = authHeader.split(' ')[1];
        
        // Check if token exists
        if (!token) {
            return res.status(401).json({
                return_code: "UNAUTHORIZED",
                message: "No token provided"
            });
        }
        
        // Verify the token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // Add the decoded user to the request object
        req.user = decoded;
        
        // Continue to the next middleware or route handler
        next();
    } catch (error) {
        // Handle token verification errors
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({
                return_code: "TOKEN_EXPIRED",
                message: "Token has expired"
            });
        } else if (error.name === 'JsonWebTokenError') {
            return res.status(401).json({
                return_code: "INVALID_TOKEN",
                message: "Invalid token"
            });
        } else {
            console.error("Auth middleware error:", error);
            return res.status(500).json({
                return_code: "SERVER_ERROR",
                message: "An error occurred during authentication"
            });
        }
    }
};

module.exports = verifyToken;
