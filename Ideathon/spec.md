# Project Specification
## Transparent Civic Grievance & Infrastructure Triage System

### 1. Project Overview
A web-based platform where citizens can report public infrastructure problems such as damaged roads, water leakage, garbage, pollution, and drainage issues.

The system evaluates the seriousness of each complaint, assigns it to the appropriate government department, and displays complaint progress through a public dashboard.

### 2. Main Objectives
- Make it easy for citizens to report public problems.
- Identify and prioritize serious complaints.
- Direct complaints to the appropriate department.
- Allow citizens to track complaint status.
- Maintain transparency through a public dashboard.

### 3. User Roles

**Citizen**
- Register and log in.
- Submit a complaint.
- Upload photos, videos, or audio.
- View and track their complaints.

**Admin / Authority**
- View all submitted complaints.
- Review complaint details and severity.
- Update complaint status.
- Assign complaints to the relevant department.

### 4. Core Features

**A. Complaint Submission**
- Complaint title.
- Category: Road Damage, Water Leakage, Garbage, Pollution, Drainage, Other.
- Description of the issue.
- Upload photo, video, or audio evidence.
- Location of the issue (address or map location).
- Submit complaint.

**B. Severity Assessment**

Automatically calculate a severity score from 0–100 using the selected issue category and simple urgency-related inputs.

Display one of three levels:
- Low: 0–39
- Medium: 40–69
- High: 70–100

Higher-severity complaints should receive higher priority.

For the first version, use a simple rule-based scoring system. Keep the scoring logic separate so AI-based assessment can be added later.

**C. Department Assignment**

Automatically assign complaints based on their category.

Examples:
- Road Damage → Public Works Department
- Water Leakage → Water Supply Department
- Garbage → Sanitation Department
- Pollution → Pollution Control Department
- Drainage → Drainage Department

**D. Complaint Tracking**

Each complaint should have one of these statuses:
- Submitted
- Under Review
- In Progress
- Resolved
- Rejected

Citizens should be able to see the latest status of their complaints.

**E. Public Dashboard**

Display:
- Total complaints.
- Pending complaints.
- In-progress complaints.
- Resolved complaints.
- Complaints by category.
- Complaints by severity.
- Recent complaints and their status.

Do not display citizens' private contact information publicly.

### 5. Main Pages

1. **Home Page** – Project introduction, key statistics, and Report an Issue button.
2. **Login / Register Page** – Citizen and admin authentication.
3. **Report Issue Page** – Form to submit a new complaint.
4. **My Complaints Page** – List of complaints submitted by the logged-in citizen.
5. **Public Dashboard** – Public complaint statistics and status overview.
6. **Admin Dashboard** – Manage complaints, update status, and assign departments.

### 6. Suggested Technology Stack
- Frontend: React.js
- Styling: CSS or Tailwind CSS
- Backend and Database: Supabase
- Authentication: Supabase Auth
- File Storage: Supabase Storage
- Charts: Recharts
- Maps: Leaflet with OpenStreetMap (optional)

### 7. Database Requirements

Create the following main tables:

**Users**
- id
- name
- email
- role (citizen/admin)

**Complaints**
- id
- user_id
- title
- category
- description
- media_url
- location
- severity_score
- severity_level
- assigned_department
- status
- created_at
- updated_at

### 8. UI Requirements
- Clean, modern, and professional design.
- Simple navigation.
- Responsive layout for mobile and desktop.
- Clear severity labels using different colors.
- Dashboard cards and charts.
- Easy-to-use complaint submission form.

### 9. Important Development Instructions
- Build a working application, not just a static UI.
- Connect the frontend to the database.
- Implement authentication and role-based access.
- Store uploaded media securely.
- Validate all form inputs.
- Ensure citizens can only manage their own complaints.
- Only admins should be able to update complaint status and assignments.
- Keep the public dashboard read-only.
- Use realistic sample data only when needed for initial demonstration.

### 10. Expected Outcome
A functional civic grievance platform where citizens can submit and track public issues, authorities can manage and prioritize complaints, and everyone can view overall complaint progress through a transparent public dashboard.