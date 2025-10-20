import { useState } from "react";
import { signup } from "../services/api.js";
import { useNavigate } from "react-router-dom";

export default function Signup(){
  const [form, setForm] = useState({ name:"", email: "", password: "", role: "Member" });
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    try{
      await signup(form);
      alert("Signup success. Please login.");
      navigate("/");
    }catch(err){
      alert(err?.response?.data?.error || "Signup failed");
    }
  };

  return (
    <div style={{maxWidth:500, margin:"40px auto", padding:20, border:"1px solid #ddd"}}>
      <h2>Signup</h2>
      <form onSubmit={handleSubmit}>
        <input placeholder="Name" value={form.name} onChange={e=>setForm({...form,name:e.target.value})} style={{width:"100%",padding:8,marginBottom:8}}/>
        <input placeholder="Email" type="email" value={form.email} onChange={e=>setForm({...form,email:e.target.value})} style={{width:"100%",padding:8,marginBottom:8}}/>
        <input placeholder="Password" type="password" value={form.password} onChange={e=>setForm({...form,password:e.target.value})} style={{width:"100%",padding:8,marginBottom:8}}/>
        <select value={form.role} onChange={e=>setForm({...form,role:e.target.value})} style={{width:"100%",padding:8,marginBottom:8}}>
          <option value="Member">Member</option>
          <option value="Executive">Executive</option>
        </select>
        <button type="submit" style={{padding:8}}>Signup</button>
      </form>
    </div>
  );
}
