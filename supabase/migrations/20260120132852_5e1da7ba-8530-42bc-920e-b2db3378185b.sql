-- Create function to auto-populate sender_name
CREATE OR REPLACE FUNCTION set_sender_name()
RETURNS TRIGGER AS $$
BEGIN
    -- Only set if sender_name is NULL and sender_role is not 'system'
    IF NEW.sender_name IS NULL AND NEW.sender_role != 'system' THEN
        SELECT TRIM(CONCAT(first_name, ' ', last_name))
        INTO NEW.sender_name
        FROM profiles
        WHERE id = NEW.sender_id;
        
        -- If still NULL, set to 'Unknown'
        IF NEW.sender_name IS NULL OR NEW.sender_name = '' THEN
            NEW.sender_name := 'Unknown';
        END IF;
    END IF;
    
    -- For system messages, ensure sender_name is 'System'
    IF NEW.sender_role = 'system' AND (NEW.sender_name IS NULL OR NEW.sender_name = '') THEN
        NEW.sender_name := 'System';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_set_sender_name ON chat_messages;
CREATE TRIGGER trigger_set_sender_name
    BEFORE INSERT ON chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION set_sender_name();