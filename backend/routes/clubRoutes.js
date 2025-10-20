import express from "express";
import Club from "../models/Club.js";
import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

router.post("/", protect, async (req, res) => {
  if (req.user.role !== "Admin") return res.status(403).json({ error: "Unauthorized" });
  try {
    const club = await Club.create(req.body);
    res.json(club);
  } catch (err) {
    res.status(400).json({ error: "Create club failed", detail: err.message });
  }
});

router.get("/", async (req, res) => {
  const clubs = await Club.find().populate("executives", "name email");
  res.json(clubs);
});

export default router;
