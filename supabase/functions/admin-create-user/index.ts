import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const ALLOWED_ROLES = ["user", "creator", "reviewer", "admin"];

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ error: "Missing server environment configuration" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing Authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const token = authHeader.replace("Bearer ", "").trim();

    // Client with user's JWT
    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: { Authorization: authHeader },
      },
    });

    // Verify authenticated user by passing the JWT token explicitly
    const {
      data: { user: caller },
      error: authError,
    } = await supabaseClient.auth.getUser(token);

    if (authError || !caller) {
      return new Response(
        JSON.stringify({ error: "Unauthorized: Invalid session" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Admin client with service_role key to bypass RLS and access auth admin API
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // Verify admin role of caller using service_role client
    const { data: callerProfile, error: profileError } = await supabaseAdmin
      .from("profiles")
      .select("role")
      .eq("id", caller.id)
      .single();

    if (profileError || !callerProfile || callerProfile.role !== "admin") {
      return new Response(
        JSON.stringify({ error: "Forbidden: Admin privileges required" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json();
    const action = body.action || "create";

    // ─────────────────────────────────────────────────────────────────────────
    // Action 1: Update existing user role
    // ─────────────────────────────────────────────────────────────────────────
    if (action === "update_role") {
      const { userId, role } = body;
      if (!userId || !role) {
        return new Response(
          JSON.stringify({ error: "userId and role are required" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      if (!ALLOWED_ROLES.includes(role)) {
        return new Response(
          JSON.stringify({ error: `Invalid role. Allowed roles: ${ALLOWED_ROLES.join(", ")}` }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const updateData: Record<string, any> = {
        role: role,
        updated_at: new Date().toISOString(),
      };

      if (role === "creator") {
        updateData.creator_status = "approved";
        updateData.creator_verified_at = new Date().toISOString();
      }

      const { error: updateError } = await supabaseAdmin
        .from("profiles")
        .update(updateData)
        .eq("id", userId);

      if (updateError) {
        return new Response(
          JSON.stringify({ error: `Failed to update user role: ${updateError.message}` }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Best-effort audit log
      try {
        await supabaseAdmin.from("moderation_actions").insert({
          actor_id: caller.id,
          target_type: "user",
          target_id: userId,
          action: "escalate",
          reason: `Admin updated role to '${role}'`,
        });
      } catch (logErr) {
        console.warn("Failed to write to moderation_actions:", logErr);
      }

      return new Response(
        JSON.stringify({ success: true, message: `Role updated to ${role} successfully` }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Action 2: Create new user & assign role
    // ─────────────────────────────────────────────────────────────────────────
    const {
      email,
      password,
      username,
      role = "user",
      firstName,
      lastName,
      emailConfirm = true,
    } = body;

    // Validation
    if (!email || typeof email !== "string" || !email.includes("@")) {
      return new Response(
        JSON.stringify({ error: "A valid email address is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!password || typeof password !== "string" || password.length < 6) {
      return new Response(
        JSON.stringify({ error: "Password must be at least 6 characters long" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!username || typeof username !== "string" || username.trim().length < 3) {
      return new Response(
        JSON.stringify({ error: "Username must be at least 3 characters long" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const cleanUsername = username.trim().toLowerCase();
    const cleanEmail = email.trim().toLowerCase();
    const cleanRole = role.toLowerCase();

    if (!ALLOWED_ROLES.includes(cleanRole)) {
      return new Response(
        JSON.stringify({ error: `Invalid role. Allowed roles: ${ALLOWED_ROLES.join(", ")}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Check if username is already taken
    const { data: existingProfile, error: usernameCheckError } = await supabaseAdmin
      .from("profiles")
      .select("id")
      .ilike("username", cleanUsername)
      .maybeSingle();

    if (usernameCheckError && usernameCheckError.code !== "PGRST116") {
      console.error("Error checking username:", usernameCheckError);
    }

    if (existingProfile) {
      return new Response(
        JSON.stringify({ error: `Username "${cleanUsername}" is already taken` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const fullName = [firstName, lastName].filter(Boolean).join(" ").trim() || cleanUsername;

    // Create user via Supabase Auth Admin API
    const { data: createData, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email: cleanEmail,
      password: password,
      email_confirm: emailConfirm,
      app_metadata: {
        role: cleanRole,
      },
      user_metadata: {
        role: cleanRole,
        username: cleanUsername,
        first_name: firstName?.trim() || null,
        last_name: lastName?.trim() || null,
        full_name: fullName,
      },
    });

    if (createError || !createData.user) {
      return new Response(
        JSON.stringify({ error: createError?.message || "Failed to create user in Auth" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const newUserId = createData.user.id;

    // Small delay to ensure on_auth_user_created trigger has executed
    await new Promise((resolve) => setTimeout(resolve, 300));

    // Update profiles table with chosen role and metadata
    const profileUpdate: Record<string, any> = {
      username: cleanUsername,
      role: cleanRole,
      updated_at: new Date().toISOString(),
    };

    if (firstName?.trim()) profileUpdate.first_name = firstName.trim();
    if (lastName?.trim()) profileUpdate.last_name = lastName.trim();

    if (cleanRole === "creator") {
      profileUpdate.creator_status = "approved";
      profileUpdate.creator_verified_at = new Date().toISOString();
    }

    // Try updating profile first since on_auth_user_created trigger creates it
    const { error: profileUpdateError } = await supabaseAdmin
      .from("profiles")
      .update(profileUpdate)
      .eq("id", newUserId);

    if (profileUpdateError) {
      console.warn("Direct profile update failed, falling back to upsert:", profileUpdateError);
      const { error: profileUpsertError } = await supabaseAdmin
        .from("profiles")
        .upsert({
          id: newUserId,
          ...profileUpdate,
        });

      if (profileUpsertError) {
        console.error("Error upserting profile:", profileUpsertError);
      }
    }

    // Best effort moderation action audit log
    try {
      await supabaseAdmin.from("moderation_actions").insert({
        actor_id: caller.id,
        target_type: "user",
        target_id: newUserId,
        action: "escalate",
        reason: `Admin created user @${cleanUsername} with role '${cleanRole}'`,
      });
    } catch (logErr) {
      console.warn("Failed to write to moderation_actions:", logErr);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "User created successfully",
        user: {
          id: newUserId,
          email: cleanEmail,
          username: cleanUsername,
          role: cleanRole,
          created_at: createData.user.created_at,
        },
      }),
      { status: 201, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    console.error("Unhandled error:", err);
    return new Response(
      JSON.stringify({ error: err.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
