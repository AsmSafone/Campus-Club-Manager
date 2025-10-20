import express from "express";
import Event from "../models/Event.js";
import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

// Create
router.post("/", protect, async (req, res) => {
  try {
    const ev = await Event.create({ ...req.body, createdBy: req.user.id });
    res.json(ev);
  } catch (err) {
    res.status(400).json({ error: "Cannot create event", detail: err.message });
  }
});

// Read all
router.get("/", async (req, res) => {
  const events = await Event.find().populate("club", "name");
  res.json(events);
});

// Register
router.post("/:id/register", protect, async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) return res.status(404).json({ error: "Event not found" });
    if (event.registeredUsers.includes(req.user.id)) return res.status(400).json({ error: "Already registered" });
    event.registeredUsers.push(req.user.id);
    await event.save();
    res.json({ message: "Registered successfully" });
  } catch (err) {
    res.status(400).json({ error: "Registration failed" });
  }
});

// Delete
router.delete("/:id", protect, async (req, res) => {
  try {
    await Event.findByIdAndDelete(req.params.id);
    res.json({ message: "Event deleted" });
  } catch {
    res.status(400).json({ error: "Delete failed" });
  }
});

export default router;
