-- Step 1: Add 'receptionist' to app_role enum
ALTER TYPE app_role ADD VALUE IF NOT EXISTS 'receptionist';