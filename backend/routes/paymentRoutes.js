import express from "express";
import Event from "../models/Event.js";
import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

router.post("/:eventId", protect, async (req, res) => {
  const event = await Event.findById(req.params.eventId);
  if (!event) return res.status(404).json({ error: "Event not found" });
  // Simulate payment success
  res.json({ message: `Payment successful for ${event.name}` });
});

export default router;
