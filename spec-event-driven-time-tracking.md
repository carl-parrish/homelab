
# Spec: Event-Driven Time Tracking Automation

**Objective:** To automatically create billable time entries in Kimai by correlating real-time development activity from Forgejo with background activity from ActivityWatch. Plane will serve as the source of truth for project and issue mapping.

---

## 1. Actors

*   **User:** The developer performing the work and writing the code.
*   **Forgejo:** The Git server hosting the code repositories.
*   **ActivityWatch (AW):** The service passively tracking the user's computer activity.
*   **n8n:** The workflow automation platform that acts as the central orchestrator.
*   **Plane:** The project management tool, source of truth for issue IDs.
*   **Kimai:** The time-tracking and billing application where the final data is stored.

---

## 2. Assumptions

*   All services are installed, running, and accessible from the n8n instance.
*   API credentials and/or tokens for all services are available to n8n.
*   The user consistently includes a Plane Issue ID in their commit messages using the format `[PROJ-123]`.

---

## 3. Workflow (Process Flow)

This workflow is initiated by a `git push` action from the user.

1.  **Trigger (Forgejo):**
    *   A Forgejo repository is configured with a **Webhook** that points to an n8n webhook URL.
    *   The webhook is set to trigger on **Push Events**.

2.  **Ingestion & Parsing (n8n):**
    *   The n8n workflow receives the webhook payload from Forgejo.
    *   It iterates through the list of commits in the payload.
    *   For each commit, it uses a regular expression (e.g., `/\[([A-Z]+-\d+)\]/`) to parse the **Plane Issue ID** from the commit message.
    *   If no Issue ID is found in a commit message, the workflow may stop for that commit or flag it for manual review.

3.  **Activity Query (n8n → ActivityWatch):**
    *   For each commit that has a valid Issue ID, the workflow makes an API call to the ActivityWatch (`aw-server`) REST API.
    *   It queries for activity events within a defined time window preceding the commit's timestamp (e.g., the last 2 hours).
    *   The query should filter for relevant activity buckets, such as code editors (VS Code), terminals, and specific browser activity.

4.  **Correlation & Calculation (n8n):**
    *   The workflow calculates the total duration (in seconds or minutes) of the filtered, relevant activity returned by ActivityWatch.
    *   **Initial Logic:** Sum the duration of all identified, relevant events in the time window.

5.  **Enrichment (n8n → Plane):**
    *   *(Optional but Recommended)* The workflow uses the parsed Issue ID to make an API call to the Plane API.
    *   It fetches the issue's title and other relevant metadata (e.g., parent project name).

6.  **Record Creation (n8n → Kimai):**
    *   The workflow authenticates with the Kimai API (likely using the built-in Kimai node).
    *   It creates a new timesheet record with the following properties:
        *   **Project:** Mapped from the Plane project ID (e.g., "PROJ").
        *   **Description:** A composite string built from the commit message and/or the fetched Plane issue title.
        *   **Duration:** The duration calculated in Step 4.
        *   **Start/End Time:** Derived from the commit timestamp and calculated duration.

---

## 4. Out of Scope (Initial Version)

*   **Complex Duration Logic:** The initial version will not attempt to intelligently detect idle time or the precise start/end of a work session beyond the fixed time window.
*   **UI/Frontend:** This system is purely a backend automation workflow.
*   **Error Correction:** There will be no UI to fix or re-assign time entries that are categorized incorrectly. This would be done directly in Kimai.
*   **Handling Commits without IDs:** The first version will simply ignore commits that don't follow the required message format.

---

## 5. Open Questions

*   What is the optimal time window for the ActivityWatch query (e.g., 1 hour, 2 hours, since last commit)?
*   How should the workflow handle a single `push` containing multiple commits with different Issue IDs? (Current assumption: process each commit individually).
*   What is the desired behavior if no relevant ActivityWatch activity is found for a given commit? (e.g., create a 0-minute entry, send a notification, or do nothing?).
