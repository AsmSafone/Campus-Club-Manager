'use client';

import { useState, useEffect } from 'react';

export default function HomePage() {
  const [isLogin, setIsLogin] = useState(true);
  const [form, setForm] = useState({
    name: '',
    email: 'admin@gmail.com',
    password: '1234',
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const checkLogin = async () => {
      const res = await fetch("/api/user");
      if (res.ok) {
        const data = await res.json();
        if (data.role) window.location.href = `/dashboard/${data.role}`;
      }
    };
    checkLogin();
  }, []);

  const handleChange = (e) => setForm({ ...form, [e.target.name]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    const endpoint = isLogin ? '/api/login' : '/api/signup';

    try {
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      });
      const data = await res.json();

      if (res.ok) {
        if (isLogin) window.location.href = `/dashboard/${data.role}`;
        else {
          alert('Signup successful! Please log in.');
          setIsLogin(true);
        }
      } else {
        alert(data.error || data.message || 'Something went wrong.');
      }
    } catch (err) {
      console.error(err);
      alert('Network error.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-100 to-indigo-200">
      <div className="bg-white p-8 rounded-2xl shadow-lg w-full max-w-md">
        <h1 className="text-2xl font-bold text-center text-indigo-600 mb-6">
          {isLogin ? 'Login' : 'Signup'}
        </h1>

        <form onSubmit={handleSubmit} className="space-y-4">
          {!isLogin && (
            <>
              <input
                name="name"
                placeholder="Full Name"
                value={form.name}
                onChange={handleChange}
                required
                className="w-full p-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-400"
              />
            </>
          )}

          <input
            type="email"
            name="email"
            placeholder="Email"
            value={form.email}
            onChange={handleChange}
            required
            className="w-full p-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-400"
          />
          <input
            type="password"
            name="password"
            placeholder="Password"
            value={form.password}
            onChange={handleChange}
            required
            className="w-full p-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-400"
          />

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-indigo-600 text-white py-3 rounded-lg hover:bg-indigo-700 transition-all"
          >
            {loading ? 'Please wait...' : isLogin ? 'Login' : 'Signup'}
          </button>
        </form>

        <p
          onClick={() => setIsLogin(!isLogin)}
          className="text-center text-indigo-600 mt-4 cursor-pointer hover:underline"
        >
          {isLogin ? "Don't have an account? Sign up" : 'Already have an account? Log in'}
        </p>
      </div>
    </div>
  );
}
