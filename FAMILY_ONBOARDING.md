# Family Onboarding Guide: Accessing Our Homelab

Welcome to our family's secure homelab! This guide will help you access our private services safely and easily.

## What is This?

Our homelab is a private computer setup at home that hosts family services like:
- 🏠 **Private family dashboard** - Control panel for our home
- 📊 **Monitoring** - See how our systems are running
- 📁 **File sharing** - Access family photos and documents
- 🎬 **Media server** - Stream our movies and music
- 🔐 **Admin tools** - For managing our home technology

## Two Types of Services

### 🌐 Public Services
These are accessible from anywhere on the internet:
- **Family website** - dknathalage.dev
- **Portfolio** - Professional content

### 🔒 Private Services  
These are only accessible to family members with Tailscale:
- **Admin dashboard** - admin-dashboard.tail[xxx].ts.net
- **Home controls** - home-assistant.tail[xxx].ts.net
- **Family files** - files.tail[xxx].ts.net
- **Media server** - media.tail[xxx].ts.net

## How to Get Access

### Step 1: Install Tailscale
Download and install Tailscale on your device:

**📱 Phone/Tablet:**
- iOS: App Store → "Tailscale"
- Android: Google Play → "Tailscale"

**💻 Computer:**
- Windows: Download from tailscale.com
- Mac: Download from tailscale.com or `brew install tailscale`
- Linux: Follow instructions at tailscale.com

### Step 2: Join Our Family Network
1. Open the Tailscale app
2. Sign in with your email (ask Dad/Mom to add you first)
3. You'll be automatically connected to our family network

### Step 3: Access Services
Once connected:

**Private Services:**
- Open your web browser
- Visit: `admin-dashboard.tail[xxx].ts.net`
- You'll see our family dashboard with all available services

**Public Services:**
- Just visit dknathalage.dev like any normal website
- No Tailscale needed for these

## Family Access Levels

### 👨‍💼 Admin (Dad/Mom)
- Full access to all services
- Can manage other family members
- Can add/remove devices

### 👨‍👩‍👧‍👦 Family Members
- Access to media, files, and basic home controls
- Cannot access admin/monitoring tools
- Can use all entertainment services

### 👶 Kids
- Limited access to appropriate content
- Entertainment services only
- No admin capabilities

## Troubleshooting

### "I can't access a service"
1. Check if Tailscale is running (green icon)
2. Try turning Tailscale off and on again
3. Ask Dad/Mom to check if you're added to the right group

### "Tailscale won't connect"
1. Make sure you're signed in with the right email
2. Check your internet connection
3. Try restarting the Tailscale app

### "I forgot the service URL"
1. Go to the family dashboard: `admin-dashboard.tail[xxx].ts.net`
2. All service links are listed there
3. Or ask Dad/Mom for the link

## Security Notes

### ✅ What's Safe:
- Using Tailscale on your personal devices
- Sharing service URLs with family members
- Accessing services when connected to Tailscale

### ❌ What to Avoid:
- Sharing your Tailscale login with friends
- Accessing services on public/school computers
- Taking screenshots of admin pages

## Getting Help

If you need help:
1. Check this guide first
2. Ask Dad/Mom
3. Try the troubleshooting steps above

## Privacy & Security

**Your Privacy:**
- Only family members can access private services
- All connections are encrypted end-to-end
- No one outside our family can see our traffic

**What We Can See:**
- Dad/Mom can see which devices are connected
- Basic connection logs for security
- No personal browsing history

**What We Can't See:**
- Your other internet browsing
- Messages or personal files on your device
- Activity when Tailscale is turned off

---

*Welcome to our family's secure digital home! 🏠*