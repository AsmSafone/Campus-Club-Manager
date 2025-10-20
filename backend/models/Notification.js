import mongoose from "mongoose";

const notificationSchema = new mongoose.Schema({
  message: String,
  date: { type: Date, default: Date.now },
  recipient: { type: mongoose.Schema.Types.ObjectId, ref: "User" }
});

export default mongoose.model("Notification", notificationSchema);
