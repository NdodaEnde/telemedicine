-- Add sender_name column to chat_messages
ALTER TABLE chat_messages 
ADD COLUMN IF NOT EXISTS sender_name TEXT;

-- Update existing messages with sender names from profiles
UPDATE chat_messages cm
SET sender_name = COALESCE(
    (SELECT TRIM(CONCAT(p.first_name, ' ', p.last_name))
     FROM profiles p 
     WHERE p.id = cm.sender_id),
    'Unknown'
)
WHERE cm.sender_name IS NULL AND cm.sender_role != 'system';

-- Set system messages sender_name
UPDATE chat_messages
SET sender_name = 'System'
WHERE sender_role = 'system' AND sender_name IS NULL;