import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { login } from "../services/api.js";

export default function Login(){
  const [form, setForm] = useState({ email: "", password: "" });
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    try{
      const { data } = await login(form);
      localStorage.setItem("token", data.token);
      localStorage.setItem("role", data.role);
      alert("Login successful");
      navigate("/dashboard");
    }catch(err){
      alert(err?.response?.data?.error || "Login failed");
    }
  };

  return (
    <div style={{maxWidth:400, margin:"40px auto", padding:20, border:"1px solid #ddd"}}>
      <h2>Login</h2>
      <form onSubmit={handleSubmit}>
        <input placeholder="Email" type="email" value={form.email} onChange={e=>setForm({...form,email:e.target.value})} style={{width:"100%",padding:8,marginBottom:8}}/>
        <input placeholder="Password" type="password" value={form.password} onChange={e=>setForm({...form,password:e.target.value})} style={{width:"100%",padding:8,marginBottom:8}}/>
        <button type="submit" style={{padding:8}}>Login</button>
      </form>
    </div>
  );
}
