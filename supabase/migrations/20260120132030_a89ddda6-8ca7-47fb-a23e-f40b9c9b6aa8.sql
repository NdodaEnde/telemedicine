-- Allow reading profiles of conversation participants
CREATE POLICY "Users can view profiles of chat participants" ON profiles
FOR SELECT
USING (
  -- User can see their own profile
  auth.uid() = id
  OR
  -- User can see profiles of people in their conversations
  id IN (
    SELECT patient_id FROM chat_conversations 
    WHERE receptionist_id = auth.uid()
    UNION
    SELECT receptionist_id FROM chat_conversations 
    WHERE patient_id = auth.uid()
  )
);