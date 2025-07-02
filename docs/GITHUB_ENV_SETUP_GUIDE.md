# How to Set Up GitHub Environments for Manual Approval

This guide explains how to configure the necessary environments in your GitHub repository. This setup is essential to enable the manual approval gates in the `deploy.yml` workflow, ensuring that no infrastructure changes are applied without explicit review.

Our workflow is configured to use two environments that require approval:
1.  `infrastructure`
2.  `platform`

You will need to create each of these in the GitHub UI. The `tenant` deployment will happen automatically without approval.

---

### Step-by-Step Instructions

Follow these steps for each of the environment names listed above (`infrastructure` and `platform`).

1.  **Navigate to Repository Settings:**
    In your GitHub repository, click on the **Settings** tab.

    ![GitHub Settings Tab](https://i.imgur.com/A6y2GfV.png)

2.  **Go to Environments:**
    In the left sidebar, click on **Environments**.

    ![GitHub Environments Menu](https://i.imgur.com/JgA5E9g.png)

3.  **Create a New Environment:**
    Click the **New environment** button.

    ![New Environment Button](https://i.imgur.com/p3v2kCg.png)

4.  **Name the Environment:**
    Enter the name of the environment (e.g., `infrastructure`) and click the **Configure environment** button.

    ![Configure Environment](https://i.imgur.com/bXv3bZf.png)

5.  **Add Protection Rules (The Approval Step):**
    This is the most important step. Scroll down to the **Deployment protection rules** section.
    - Check the box for **Required reviewers**.
    - In the search box that appears, type the GitHub username or team name of the person(s) who should be responsible for approving deployments to this environment. You can add up to 6 reviewers.
    - *Note: You cannot add yourself as a required reviewer for an environment.*

    ![Add Required Reviewers](https://i.imgur.com/sL8fGkR.png)

6.  **Save the Rules:**
    Click **Save protection rules**.

7.  **Repeat for Other Environments:**
    Repeat steps 3 through 6 for the `platform` environment.

---

### What Happens Next?

Once these environments are configured, any time the `deploy.yml` workflow reaches an `apply` job, it will automatically pause. The users you designated as "Required reviewers" will receive a notification. They will then need to go to the workflow run in GitHub, review the plan, and click "Approve and deploy" to allow the workflow to proceed.
