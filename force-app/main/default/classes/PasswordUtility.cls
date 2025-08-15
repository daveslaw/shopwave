public class PasswordUtility {
    // Generate a random salt (16 chars, alphanumeric)
    public static String generateSalt(Integer length) {
        Blob saltBlob = Crypto.generateAesKey(128); // Cryptographically secure random
        String salt = EncodingUtil.base64Encode(saltBlob).replaceAll('[^a-zA-Z0-9]', '');
        return salt.substring(0, length);
    }

    // Hash password with new salt (for registration)
    public static Map<String, String> hashPassword(String plainPassword) {
        if (String.isBlank(plainPassword)) {
            throw new CustomException('Password cannot be empty', 400);
        }
        String salt = generateSalt(16);
        String saltedPassword = plainPassword + salt;
        Blob hashed = Crypto.generateDigest('SHA-256', Blob.valueOf(saltedPassword));
        String hashedPassword = EncodingUtil.base64Encode(hashed);
        return new Map<String, String>{ 'hash' => hashedPassword, 'salt' => salt };
    }

    // Hash input password with existing salt (for login verification)
    public static String hashPasswordWithSalt(String plainPassword, String salt) {
        if (String.isBlank(plainPassword) || String.isBlank(salt)) {
            throw new CustomException('Invalid password or salt', 400);
        }
        String saltedPassword = plainPassword + salt;
        Blob hashed = Crypto.generateDigest('SHA-256', Blob.valueOf(saltedPassword));
        return EncodingUtil.base64Encode(hashed);
    }

    public class CustomException extends Exception {
        public Integer statusCode;
        public CustomException(String message, Integer code) {
            this.setMessage(message);
            this.statusCode = code;
        }
    }
}