export async function registerUser() {
  const name = document.getElementById("reg-name").value.trim();
  const username = document.getElementById("reg-username").value.trim();
  const password = document.getElementById("reg-password").value.trim();

  // ✅ Basic client-side validation
  if (name.length < 2 || name.length > 50) {
    alert("Name must be between 2 and 50 characters");
    return;
  }
  if (username.length < 3 || username.length > 30) {
    alert("Username must be between 3 and 30 characters");
    return;
  }
  if (password.length < 8 || password.length > 128) {
    alert("Password must be between 8 and 128 characters");
    return;
  }

  const dto = { name, username, password };
  console.log(dto);
  try {
    const response = await fetch("http://localhost:4001", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(dto),
    });
    console.log(dto);
    if (response.ok) {
      const data = await response.json();
      alert("User registered successfully!");
      console.log("✅ Response:", data);
    } else {
      const error = await response.json();
      alert(
        "❌ Registration failed: " + (error.message || response.statusText)
      );
    }
  } catch (err) {
    console.error("Request failed:", err);
    alert("❌ Network error: " + err.message);
  }
}
