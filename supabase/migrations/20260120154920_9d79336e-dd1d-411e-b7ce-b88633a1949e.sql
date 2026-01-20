-- ============================================
-- HCF Platform - RLS Policy Improvements
-- ============================================

-- ============================================
-- STEP 1: Add Receptionist Access to Profiles
-- ============================================

-- Drop conflicting policies if they exist
DROP POLICY IF EXISTS "Clinicians can view patient profiles " ON profiles;

-- Staff (including receptionists) can view all profiles
CREATE POLICY "Staff can view all profiles" ON profiles
    FOR SELECT USING (
        has_role(auth.uid(), 'admin'::app_role) OR 
        has_role(auth.uid(), 'nurse'::app_role) OR 
        has_role(auth.uid(), 'doctor'::app_role) OR 
        has_role(auth.uid(), 'receptionist'::app_role)
    );

-- ============================================
-- STEP 2: Staff Access to User Roles
-- ============================================

-- Staff can view all roles (needed to identify clinicians)
CREATE POLICY "Staff can view all roles" ON user_roles
    FOR SELECT USING (
        has_role(auth.uid(), 'admin'::app_role) OR 
        has_role(auth.uid(), 'nurse'::app_role) OR 
        has_role(auth.uid(), 'doctor'::app_role) OR 
        has_role(auth.uid(), 'receptionist'::app_role)
    );

-- ============================================
-- STEP 3: Improve Appointments Policies
-- ============================================

-- Drop existing policies to recreate with better access
DROP POLICY IF EXISTS "Admins can view all appointments " ON appointments;
DROP POLICY IF EXISTS "Patients can view their own appointments " ON appointments;
DROP POLICY IF EXISTS "Clinicians can view their appointments " ON appointments;
DROP POLICY IF EXISTS "Clinicians can update their appointments " ON appointments;
DROP POLICY IF EXISTS "Patients can create appointments " ON appointments;
DROP POLICY IF EXISTS "Patients can update their pending appointments " ON appointments;

-- Patients can view their own appointments
CREATE POLICY "Patients can view own appointments" ON appointments
    FOR SELECT USING (auth.uid() = patient_id);

-- Clinicians can view appointments assigned to them
CREATE POLICY "Clinicians can view assigned appointments" ON appointments
    FOR SELECT USING (auth.uid() = clinician_id);

-- Staff can view all appointments
CREATE POLICY "Staff can view all appointments" ON appointments
    FOR SELECT USING (
        has_role(auth.uid(), 'admin'::app_role) OR 
        has_role(auth.uid(), 'nurse'::app_role) OR 
        has_role(auth.uid(), 'doctor'::app_role) OR 
        has_role(auth.uid(), 'receptionist'::app_role)
    );

-- Staff can create appointments
CREATE POLICY "Staff can create appointments" ON appointments
    FOR INSERT WITH CHECK (
        has_role(auth.uid(), 'admin'::app_role) OR 
        has_role(auth.uid(), 'nurse'::app_role) OR 
        has_role(auth.uid(), 'doctor'::app_role) OR 
        has_role(auth.uid(), 'receptionist'::app_role)
    );

-- Patients can create their own appointments
CREATE POLICY "Patients can create own appointments" ON appointments
    FOR INSERT WITH CHECK (auth.uid() = patient_id);

-- Staff can update appointments
CREATE POLICY "Staff can update appointments" ON appointments
    FOR UPDATE USING (
        has_role(auth.uid(), 'admin'::app_role) OR 
        has_role(auth.uid(), 'nurse'::app_role) OR 
        has_role(auth.uid(), 'doctor'::app_role) OR 
        has_role(auth.uid(), 'receptionist'::app_role)
    );

-- Clinicians can update their own appointments
CREATE POLICY "Clinicians can update own appointments" ON appointments
    FOR UPDATE USING (auth.uid() = clinician_id);

-- Patients can update their pending appointments
CREATE POLICY "Patients can update pending appointments" ON appointments
    FOR UPDATE USING (auth.uid() = patient_id AND status = 'pending'::appointment_status);