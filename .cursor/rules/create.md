# PROJECT DOCUMENTATION SETUP

## 1. PROJECT REVIEW

First, review the complete Flutter project structure and understand the existing implementation.

Review:

* Flutter project structure
* Dart files
* Screens
* Widgets
* Navigation
* State management
* API integration
* Models
* Authentication
* Assets
* Android configuration
* iOS configuration
* Existing packages and dependencies

Do not modify application code during this review.

---

## 2. CREATE DOCUMENTATION FOLDER

Create the following folder:

`.cursor/docs/`

Inside this folder, create the required Markdown documentation files.

---

## 3. REQUIRED DOCUMENTATION FILES

Create these files:

### Architecture.md

Document:

* Project architecture
* Folder structure
* Main application flow
* Screen structure
* Navigation structure
* State management approach
* Reusable components
* Important architectural conventions

Document the **actual project implementation**. Do not invent architecture.

### DatabaseApi.md

Document:

* .NET Core API integration
* API Base URL configuration
* Authentication/Login flow
* API communication pattern
* Request/Response structure
* API models
* CRUD pattern
* Error handling
* Token/session handling
* Important API conventions

Do not invent endpoints or fields. Document only what is found in the project or provided API.

### Change_Log.md

Create a change log document.

Use this format:

* Date
* Change
* Files/Area affected
* Short description

Initially document the project documentation setup itself.

### UI.md

Document:

* UI structure
* Theme
* Colors
* Typography
* Common widgets
* Forms
* Buttons
* Dialogs
* Lists
* Responsive design approach
* Android/iOS UI considerations

Document the actual implementation only.

### Mobile.md

Document mobile-specific requirements:

* Android configuration
* iOS configuration
* Permissions
* Platform-specific implementation
* Device compatibility
* Responsive behavior
* Build considerations
* Any Android/iOS specific dependencies

Document only what actually exists in the project.

### Development_Guidelines.md

Document important development conventions found in the project:

* Naming conventions
* Coding patterns
* File organization
* API usage pattern
* State management rules
* Widget usage
* Error handling
* Resource disposal
* Package usage

Keep this document concise.

---

## 4. DOCUMENTATION RULES

* Documentation must describe the **actual current project**.
* Do not guess or invent information.
* Do not add unnecessary documentation.
* Keep each `.md` file focused on its specific purpose.
* Avoid duplicate information between files.
* Use Markdown headings with `#`, `##`, and `###`.
* Keep documentation concise and easy for Cursor to understand.
* These documents will be used as project reference files for future development.

---

## 5. STRICT CODE RULE

This task is documentation only.

Do NOT:

* Modify Dart code.
* Modify API code.
* Modify Android code.
* Modify iOS code.
* Change UI.
* Change dependencies.
* Refactor the project.
* Fix unrelated issues.

Only create/update the required `.md` files inside:

`.cursor/docs/`

---

## 6. FINAL REVIEW

After creating the documentation:

* Verify all `.md` files are created correctly.
* Verify the information matches the actual project.
* Remove duplicate or unnecessary content.
* Make sure the documentation is concise.
* Do not make any application code changes.
