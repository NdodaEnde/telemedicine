-- Fix function search_path security warning
CREATE OR REPLACE FUNCTION update_conversation_on_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE chat_conversations
    SET 
        last_message = LEFT(NEW.content, 100),
        last_message_at = NEW.created_at,
        updated_at = NOW(),
        unread_count = unread_count + 1
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql
SET search_path = public;