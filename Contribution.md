### 🚀 LeafGuard: Push & Contribution Strategy

Follow these 4 phases for every task. Never push directly to `main`.

#### Phase 1: Local Setup

Before starting a new task, always make sure your local code is up to date with the latest version of LeafGuard.

_git checkout main_

_git pull origin main_


#### Phase 2: Create Your Feature Branch

Create a branch using your assigned prefix. This keeps our work organized by department.

 Template: _git checkout -b prefix/task-name_
 
_git checkout -b mobile/camera-integration_

 or
 
_git checkout -b ml/disease-model-v2_


#### Phase 3: Committing & Pushing

As you work, save your progress with descriptive messages.

  _git status_
  
  _git add ._
  
  _git commit -m "feat: added real-time leaf segmentation"_
  
  _git push origin <your-branch-name>_

#### Commit Message Standard

Don't just write "fixed code." Use Conventional Commits so the project history is searchable.

    feat: (new feature for the user, not a new feature for build script)

    fix: (bug fix for the user, not a fix to a build script)

    style: (formatting, missing semi colons, etc; no production code change)

#### Phase 4: The Review Process (GitHub)

1. Open a Pull Request (PR): Go to GitHub and click "New Pull Request."
2. Select Branches: Compare main ← your-branch.
3. Request Review: Assign at least one teammate from your role to check your code.
4. The "Green Square" Rule: Once your peer approves, the Project Lead will Squash and Merge. Your contribution will then officially appear on your GitHub profile graph!
