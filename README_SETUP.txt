CLASS ROUTINE — FULL ONLINE-READY PACKAGE
=============================================

This package preserves/builds the requested app modules:
- Original weekly university timetable from the supplied image (editable, add/delete classes)
- Personal study plan (5:00 AM to 1:00 AM), subject/topic/time and completion
- University attendance records with Bangladesh-time (Asia/Dhaka) class-window check; old records can be edited
- Separate university attendance and personal-study progress
- Quiz-01/02/03/04, assignments, presentations with date, time, room, deadline, status and notes
- Subject materials (PDF, PowerPoint, books, documents, links); local demo files limited to 1.5 MB; cloud upload UI supports files up to 50 MB, subject to provider/plan limits
- Focus timer, dashboard, course-wise reports, backup/restore and attendance CSV export
- Live Bangladesh-time clock and an embedded link to the official NextClass app, including its routine, cover-page generator, teachers, rooms, contacts and events
- DIU Apps shortcuts to BLC, Student Portal and 1Card; these open the official sites in a new tab and do not collect portal passwords
- Automatic class timers based on the Bangladesh-time timetable. Timer records are restored from the scheduled start/end if the app is reopened during or after class; attendance is never automatic and must be confirmed with “Mark present” during class
- App branding: Class Routine · Developed by Md Asraful Islam
- Original calendar-and-clock app icon / PWA metadata for laptop and iPhone

IMPORTANT
---------
This is a deploy-ready starting package, NOT yet a live hosted/synced service.
Google login and cloud sync work only after you configure the publishable key, Google OAuth provider, database, and hosting. Phone/SMS login additionally requires an SMS provider.
Do not put your real password, SMS code, or private data in a demo deployment.

SETUP GOOGLE / GMAIL LOGIN + CLOUD SYNC
----------------------------------------
1. In index.html, replace PASTE_YOUR_SUPABASE_PUBLISHABLE_KEY_HERE with the publishable key from Supabase Project Settings > API Keys. It usually starts with sb_publishable_. The Project URL is already configured. Never put a service_role or secret key in frontend code.
2. In Supabase Dashboard > SQL Editor, run all of supabase_setup.sql.
3. In Supabase Dashboard > Authentication > Sign In / Providers, enable Google.
4. In Google Cloud Console, create an OAuth Client ID for a Web application. In Google Cloud's Authorized redirect URIs, add the callback URL shown on the Supabase Google provider configuration page. Copy the Google Client ID and Client Secret into the Supabase Google provider settings. Never put the Google Client Secret in index.html or share it in chat.
5. In Supabase Dashboard > Authentication > URL Configuration, set your deployed HTTPS website as the Site URL and add it to the Redirect URLs list. If testing locally, add the exact local origin you use.
6. Deploy this folder to an HTTPS host (such as Netlify or Vercel). Upload the CONTENTS of the folder, not the ZIP file as a web page.
7. Open the deployed HTTPS URL on laptop and iPhone and choose “Continue with Google / Gmail” with the same Google account. Cloud data is stored per authenticated account in study_data.
8. On iPhone Safari: Share > Add to Home Screen. On Chrome desktop: use the install icon in the address bar or menu > Save and share > Install page as app (wording can vary).

OPTIONAL PHONE / SMS LOGIN
--------------------------
The existing phone + password + SMS OTP flow is still available. To use it, enable Phone authentication and configure a supported SMS provider in Supabase. SMS delivery may cost money. Google/Gmail login does not require SMS OTP.

LOCAL DEMO
----------
“Continue in Local Demo” allows you to test features on the current browser/device only. It does not sync across devices. Back up with the Backup button.

LIMITATIONS / SAFETY
--------------------
- App is not live until you add the publishable key, configure Google OAuth, run the SQL, and deploy it.
- The app now calculates current date, weekday, class timers and attendance windows using Bangladesh time (Asia/Dhaka), independent of the laptop/iPhone timezone. Class timers are duration trackers, not proof of attendance. Attendance is recorded only when you click “Mark present” during the scheduled class window; it cannot prove physical attendance.
- The screenshot's timetable text is small; all seeded classes can be edited or removed.
- The NextClass tab loads https://eeediu.vercel.app/ directly, so its official features stay current and require an internet connection. NextClass remains a separate service: its login, routine, and data are not merged or synchronized with this app's Supabase/local records. Use “Open NextClass separately” if embedded sign-in, downloads, or browser storage are restricted.
- Cloud file upload uses a private Supabase Storage bucket. The app uploads files to the private Supabase Storage bucket when signed in to configured cloud mode. Set the bucket file-size limit in Supabase Storage settings (up to 50 MB for this app UI, subject to your Supabase plan). Provider/plan limits still apply. For downloads, ensure your app uses authenticated/signed links; do not make the bucket public for private course materials.
- Use a strong unique password and never share SMS codes.
