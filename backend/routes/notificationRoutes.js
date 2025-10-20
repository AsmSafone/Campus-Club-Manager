import express from "express";
import Notification from "../models/Notification.js";
import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

router.post("/", protect, async (req, res) => {
  if (!["Admin","Executive"].includes(req.user.role)) return res.status(403).json({ error: "Unauthorized" });
  const note = await Notification.create(req.body);
  res.json(note);
});

router.get("/", protect, async (req, res) => {
  const notes = await Notification.find({ recipient: req.user.id });
  res.json(notes);
});

export default router;
