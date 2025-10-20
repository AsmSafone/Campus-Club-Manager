import { Routes, Route, Link } from "react-router-dom";
import Login from "./pages/Login.jsx";
import Signup from "./pages/Signup.jsx";
import Dashboard from "./pages/Dashboard.jsx";
import Notifications from "./pages/Notifications.jsx";

export default function App(){
  return (
    <div>
      <nav style={{padding:10, borderBottom:"1px solid #ddd"}}>
        <Link to="/">Login</Link> | <Link to="/signup">Signup</Link> | <Link to="/dashboard">Dashboard</Link> | <Link to="/notifications">Notifications</Link>
      </nav>
      <Routes>
        <Route path="/" element={<Login/>} />
        <Route path="/signup" element={<Signup/>} />
        <Route path="/dashboard" element={<Dashboard/>} />
        <Route path="/notifications" element={<Notifications/>} />
      </Routes>
    </div>
  );
}
