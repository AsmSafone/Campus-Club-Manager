import { useEffect, useState } from "react";
import { getEvents, registerEvent, payForEvent, createEvent } from "../services/api.js";

export default function Dashboard(){
  const [events, setEvents] = useState([]);
  const [form, setForm] = useState({ name:"", description:"", date:"", venue:"", price:0 });

  useEffect(()=>{ refresh(); }, []);

  const refresh = async () => {
    const { data } = await getEvents();
    setEvents(data);
  };

  const handleRegister = async (id) => {
    try{
      await registerEvent(id);
      alert("Registered!");
    }catch(err){ alert(err?.response?.data?.error || "Failed"); }
  };

  const handlePay = async (id) => {
    try{
      await payForEvent(id);
      alert("Payment simulated");
    }catch(err){ alert("Payment failed"); }
  };

  const handleCreate = async (e) => {
    e.preventDefault();
    try{
      await createEvent(form);
      alert("Event created");
      setForm({ name:"", description:"", date:"", venue:"", price:0 });
      refresh();
    }catch(err){ alert(err?.response?.data?.error || "Create failed"); }
  };

  return (
    <div style={{padding:20}}>
      <h2>Dashboard - Events</h2>

      <div style={{display:"flex",gap:20}}>
        <div style={{flex:1}}>
          <h3>Create Event</h3>
          <form onSubmit={handleCreate} style={{border:"1px solid #ddd", padding:10}}>
            <input placeholder="Name" value={form.name} onChange={e=>setForm({...form,name:e.target.value})} style={{width:"100%",padding:6,marginBottom:6}}/>
            <input placeholder="Description" value={form.description} onChange={e=>setForm({...form,description:e.target.value})} style={{width:"100%",padding:6,marginBottom:6}}/>
            <input placeholder="Date" type="date" value={form.date} onChange={e=>setForm({...form,date:e.target.value})} style={{width:"100%",padding:6,marginBottom:6}}/>
            <input placeholder="Venue" value={form.venue} onChange={e=>setForm({...form,venue:e.target.value})} style={{width:"100%",padding:6,marginBottom:6}}/>
            <input placeholder="Price" type="number" value={form.price} onChange={e=>setForm({...form,price:parseFloat(e.target.value)})} style={{width:"100%",padding:6,marginBottom:6}}/>
            <button type="submit">Create</button>
          </form>
        </div>

        <div style={{flex:2}}>
          <h3>Available Events</h3>
          {events.map(ev=>(
            <div key={ev._id} style={{border:"1px solid #ccc", padding:10, marginBottom:8}}>
              <h4>{ev.name}</h4>
              <p>{ev.description}</p>
              <p><b>Date:</b> {ev.date ? new Date(ev.date).toLocaleDateString() : "TBD"}</p>
              <p><b>Venue:</b> {ev.venue}</p>
              <p><b>Price:</b> ${ev.price}</p>
              <button onClick={()=>handleRegister(ev._id)} style={{marginRight:8}}>Register</button>
              <button onClick={()=>handlePay(ev._id)}>Pay</button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
