import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface TestUser {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  role: "nurse" | "doctor";
  hpcsaNumber: string;
}

const testUsers: TestUser[] = [
  {
    email: "ca1@hcf.test",
    password: "password123",
    firstName: "Thandiwe",
    lastName: "Nkosi",
    role: "nurse",
    hpcsaNumber: "HN-001-TST",
  },
  {
    email: "ca2@hcf.test",
    password: "password123",
    firstName: "Sipho",
    lastName: "Mokoena",
    role: "nurse",
    hpcsaNumber: "HN-002-TST",
  },
  {
    email: "dr1@hcf.test",
    password: "password123",
    firstName: "Nomsa",
    lastName: "Dlamini",
    role: "doctor",
    hpcsaNumber: "MP-001-TST",
  },
];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    const results: { email: string; status: string; error?: string }[] = [];

    for (const user of testUsers) {
      // Check if user already exists
      const { data: existingUsers } = await supabaseAdmin.auth.admin.listUsers();
      const exists = existingUsers?.users?.some((u) => u.email === user.email);

      if (exists) {
        results.push({ email: user.email, status: "already_exists" });
        continue;
      }

      // Create the user with metadata
      const { data, error } = await supabaseAdmin.auth.admin.createUser({
        email: user.email,
        password: user.password,
        email_confirm: true,
        user_metadata: {
          first_name: user.firstName,
          last_name: user.lastName,
          role: user.role,
        },
      });

      if (error) {
        results.push({ email: user.email, status: "error", error: error.message });
        continue;
      }

      // Update clinician_profiles with HPCSA number
      if (data.user) {
        const { error: profileError } = await supabaseAdmin
          .from("clinician_profiles")
          .update({ hpcsa_number: user.hpcsaNumber })
          .eq("id", data.user.id);

        if (profileError) {
          console.warn(`Could not update HPCSA for ${user.email}:`, profileError.message);
        }
      }

      results.push({ email: user.email, status: "created" });
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Test users seeding complete",
        results,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    console.error("Seed error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});
