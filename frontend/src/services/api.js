import axios from "axios";
const API = axios.create({ baseURL: "http://localhost:5000/api" });

API.interceptors.request.use((req) => {
  const token = localStorage.getItem("token");
  if (token) req.headers.Authorization = `Bearer ${token}`;
  return req;
});

export default API;
export const login = (data) => API.post("/auth/login", data);
export const signup = (data) => API.post("/auth/signup", data);
export const getEvents = () => API.get("/events");
export const createEvent = (data) => API.post("/events", data);
export const registerEvent = (id) => API.post(`/events/${id}/register`);
export const payForEvent = (id) => API.post(`/payments/${id}`);
export const getNotifications = () => API.get("/notifications");
