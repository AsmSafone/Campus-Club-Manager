import mongoose from "mongoose";

const eventSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: String,
  date: Date,
  venue: String,
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
  club: { type: mongoose.Schema.Types.ObjectId, ref: "Club" },
  price: { type: Number, default: 0 },
  registeredUsers: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }]
}, { timestamps: true });

export default mongoose.model("Event", eventSchema);
