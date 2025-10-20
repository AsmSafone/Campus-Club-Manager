import mongoose from "mongoose";

const clubSchema = new mongoose.Schema({
  name: { type: String, unique: true, required: true },
  description: String,
  executives: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
  createdAt: { type: Date, default: Date.now }
});

export default mongoose.model("Club", clubSchema);
