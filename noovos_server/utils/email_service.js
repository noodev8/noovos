/*
=======================================================================================================================================
Email Service Utility
=======================================================================================================================================
Purpose: Provides email functionality using Resend.com for user authentication flows
Includes: Email verification, password reset, and notification emails
=======================================================================================================================================
*/

const { Resend } = require('resend');
const crypto = require('crypto');

// Initialize Resend with API key from environment variables
const resend = new Resend(process.env.RESEND_API_KEY);

// Email configuration from environment variables
const EMAIL_FROM = process.env.EMAIL_FROM || 'no-reply@api.noodev8.com';
const EMAIL_NAME = process.env.EMAIL_NAME || 'Noovos';
const FRONTEND_URL = process.env.FRONTEND_URL || 'https://api.noodev8.com';
const EMAIL_VERIFICATION_URL = process.env.EMAIL_VERIFICATION_URL || 'https://test.splitleague.noodev8.com';

/**
 * Generate a random token for verification or password reset
 * @param {number} length - Length of the token (default: 32)
 * @returns {string} - Random token string
 */
function generateToken(length = 32) {
    return crypto.randomBytes(length).toString('hex');
}

/**
 * Send email verification email to user
 * @param {string} email - User's email address
 * @param {string} name - User's name
 * @param {string} verificationToken - Verification token
 * @returns {Promise<Object>} - Resend API response
 */
async function sendVerificationEmail(email, name, verificationToken) {
    try {
        // Create verification URL
        const verificationUrl = `${EMAIL_VERIFICATION_URL}/verify-email?token=${verificationToken}`;

        // HTML email template
        const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Email Verification - ${EMAIL_NAME}</title>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background-color: #007bff; color: white; padding: 20px; text-align: center; }
                .content { padding: 20px; background-color: #f9f9f9; }
                .button { display: inline-block; padding: 12px 24px; background-color: #007bff; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
                .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>${EMAIL_NAME}</h1>
                    <h2>Email Verification Required</h2>
                </div>
                <div class="content">
                    <p>Hello ${name},</p>
                    <p>Thank you for registering with ${EMAIL_NAME}! To complete your registration, please verify your email address by clicking the button below:</p>
                    <p style="text-align: center;">
                        <a href="${verificationUrl}" class="button">Verify Email Address</a>
                    </p>
                    <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
                    <p style="word-break: break-all;">${verificationUrl}</p>
                    <p>This verification link will expire in 24 hours for security reasons.</p>
                    <p>If you didn't create an account with us, please ignore this email.</p>
                </div>
                <div class="footer">
                    <p>&copy; 2024 ${EMAIL_NAME}. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        `;

        // Plain text fallback
        const textContent = `
        Hello ${name},

        Thank you for registering with ${EMAIL_NAME}! To complete your registration, please verify your email address by visiting this link:

        ${verificationUrl}

        This verification link will expire in 24 hours for security reasons.

        If you didn't create an account with us, please ignore this email.

        Best regards,
        The ${EMAIL_NAME} Team
        `;

        // Send email using Resend
        const result = await resend.emails.send({
            from: `${EMAIL_NAME} <${EMAIL_FROM}>`,
            to: email,
            subject: `Verify your email address - ${EMAIL_NAME}`,
            html: htmlContent,
            text: textContent
        });

        console.log('Verification email sent successfully:', result);
        return result;

    } catch (error) {
        console.error('Error sending verification email:', error);
        throw error;
    }
}

/**
 * Send password reset email to user
 * @param {string} email - User's email address
 * @param {string} name - User's name
 * @param {string} resetToken - Password reset token
 * @returns {Promise<Object>} - Resend API response
 */
async function sendPasswordResetEmail(email, name, resetToken) {
    try {
        // Create reset URL
        const resetUrl = `${EMAIL_VERIFICATION_URL}/reset-password?token=${resetToken}`;

        // HTML email template
        const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Password Reset - ${EMAIL_NAME}</title>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background-color: #dc3545; color: white; padding: 20px; text-align: center; }
                .content { padding: 20px; background-color: #f9f9f9; }
                .button { display: inline-block; padding: 12px 24px; background-color: #dc3545; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
                .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
                .warning { background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 10px; border-radius: 5px; margin: 15px 0; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>${EMAIL_NAME}</h1>
                    <h2>Password Reset Request</h2>
                </div>
                <div class="content">
                    <p>Hello ${name},</p>
                    <p>We received a request to reset your password for your ${EMAIL_NAME} account. If you made this request, click the button below to reset your password:</p>
                    <p style="text-align: center;">
                        <a href="${resetUrl}" class="button">Reset Password</a>
                    </p>
                    <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
                    <p style="word-break: break-all;">${resetUrl}</p>
                    <div class="warning">
                        <strong>Important:</strong> This password reset link will expire in 1 hour for security reasons.
                    </div>
                    <p>If you didn't request a password reset, please ignore this email. Your password will remain unchanged.</p>
                </div>
                <div class="footer">
                    <p>&copy; 2024 ${EMAIL_NAME}. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        `;

        // Plain text fallback
        const textContent = `
        Hello ${name},

        We received a request to reset your password for your ${EMAIL_NAME} account. If you made this request, visit this link to reset your password:

        ${resetUrl}

        This password reset link will expire in 1 hour for security reasons.

        If you didn't request a password reset, please ignore this email. Your password will remain unchanged.

        Best regards,
        The ${EMAIL_NAME} Team
        `;

        // Send email using Resend
        const result = await resend.emails.send({
            from: `${EMAIL_NAME} <${EMAIL_FROM}>`,
            to: email,
            subject: `Password Reset Request - ${EMAIL_NAME}`,
            html: htmlContent,
            text: textContent
        });

        console.log('Password reset email sent successfully:', result);
        return result;

    } catch (error) {
        console.error('Error sending password reset email:', error);
        throw error;
    }
}

/**
 * Send email verification success notification
 * @param {string} email - User's email address
 * @param {string} name - User's name
 * @returns {Promise<Object>} - Resend API response
 */
async function sendVerificationSuccessEmail(email, name) {
    try {
        // HTML email template
        const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Email Verified - ${EMAIL_NAME}</title>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background-color: #28a745; color: white; padding: 20px; text-align: center; }
                .content { padding: 20px; background-color: #f9f9f9; }
                .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>${EMAIL_NAME}</h1>
                    <h2>Email Successfully Verified!</h2>
                </div>
                <div class="content">
                    <p>Hello ${name},</p>
                    <p>Great news! Your email address has been successfully verified. Your ${EMAIL_NAME} account is now fully activated and ready to use.</p>
                    <p>You can now enjoy all the features and services we offer.</p>
                    <p>Thank you for joining ${EMAIL_NAME}!</p>
                </div>
                <div class="footer">
                    <p>&copy; 2024 ${EMAIL_NAME}. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        `;

        // Plain text fallback
        const textContent = `
        Hello ${name},

        Great news! Your email address has been successfully verified. Your ${EMAIL_NAME} account is now fully activated and ready to use.

        You can now enjoy all the features and services we offer.

        Thank you for joining ${EMAIL_NAME}!

        Best regards,
        The ${EMAIL_NAME} Team
        `;

        // Send email using Resend
        const result = await resend.emails.send({
            from: `${EMAIL_NAME} <${EMAIL_FROM}>`,
            to: email,
            subject: `Email Verified - Welcome to ${EMAIL_NAME}!`,
            html: htmlContent,
            text: textContent
        });

        console.log('Verification success email sent successfully:', result);
        return result;

    } catch (error) {
        console.error('Error sending verification success email:', error);
        throw error;
    }
}

/**
 * Send password change confirmation email
 * @param {string} email - User's email address
 * @param {string} name - User's name
 * @returns {Promise<Object>} - Resend API response
 */
async function sendPasswordChangeConfirmationEmail(email, name) {
    try {
        // HTML email template
        const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Password Changed - ${EMAIL_NAME}</title>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background-color: #28a745; color: white; padding: 20px; text-align: center; }
                .content { padding: 20px; background-color: #f9f9f9; }
                .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
                .warning { background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 10px; border-radius: 5px; margin: 15px 0; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>${EMAIL_NAME}</h1>
                    <h2>Password Changed Successfully</h2>
                </div>
                <div class="content">
                    <p>Hello ${name},</p>
                    <p>This email confirms that your password has been successfully changed for your ${EMAIL_NAME} account.</p>
                    <div class="warning">
                        <strong>Security Notice:</strong> If you did not make this change, please contact our support team immediately.
                    </div>
                    <p>For your security, we recommend:</p>
                    <ul>
                        <li>Using a strong, unique password</li>
                        <li>Not sharing your password with anyone</li>
                        <li>Logging out of shared devices</li>
                    </ul>
                    <p>Thank you for keeping your account secure!</p>
                </div>
                <div class="footer">
                    <p>&copy; 2024 ${EMAIL_NAME}. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        `;

        // Plain text fallback
        const textContent = `
        Hello ${name},

        This email confirms that your password has been successfully changed for your ${EMAIL_NAME} account.

        If you did not make this change, please contact our support team immediately.

        For your security, we recommend:
        - Using a strong, unique password
        - Not sharing your password with anyone
        - Logging out of shared devices

        Thank you for keeping your account secure!

        Best regards,
        The ${EMAIL_NAME} Team
        `;

        // Send email using Resend
        const result = await resend.emails.send({
            from: `${EMAIL_NAME} <${EMAIL_FROM}>`,
            to: email,
            subject: `Password Changed - ${EMAIL_NAME}`,
            html: htmlContent,
            text: textContent
        });

        console.log('Password change confirmation email sent successfully:', result);
        return result;

    } catch (error) {
        console.error('Error sending password change confirmation email:', error);
        throw error;
    }
}

// Export all functions
module.exports = {
    generateToken,
    sendVerificationEmail,
    sendPasswordResetEmail,
    sendVerificationSuccessEmail,
    sendPasswordChangeConfirmationEmail
};
