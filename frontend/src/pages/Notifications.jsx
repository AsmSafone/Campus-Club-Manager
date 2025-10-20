import { useEffect, useState } from "react";
import { getNotifications } from "../services/api.js";

export default function Notifications(){
  const [notes, setNotes] = useState([]);
  useEffect(()=>{ load(); }, []);
  const load = async ()=> {
    try{
      const { data } = await getNotifications();
      setNotes(data);
    }catch(err){ console.log(err); }
  };
  return (
    <div style={{padding:20}}>
      <h2>Notifications</h2>
      {notes.length===0 && <p>No notifications</p>}
      {notes.map(n=>(
        <div key={n._id} style={{border:"1px solid #ddd", padding:10, marginBottom:8}}>
          <p>{n.message}</p>
          <small>{new Date(n.date).toLocaleString()}</small>
        </div>
      ))}
    </div>
  );
}
