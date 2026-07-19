# Local 2026 data-entry dashboard

This Shiny app edits the five CSV trackers used by the public 2026 Quarto
dashboard. It runs only on the local computer and binds to `127.0.0.1`.
GitHub Pages publishes the read-only Quarto output and cannot run this app or
write to the repository.

From the repository root, start it with:

```sh
Rscript tools/data-entry/run.R
```

The launcher installs `shiny` and `DT` from CRAN if they are not already
available. Close the R process or press Control-C in the terminal to stop the
app.

## Workflow

1. Double-click cells to edit them, or add and delete rows.
2. Select **Validate**. Blank or duplicate identifiers prevent saving;
   unfamiliar status values generate warnings.
3. Select **Save all changes**. The app checks for outside file changes, writes
   timestamped backups under `uncommitted/data-entry-backups/`, and runs the
   repository manifest validator.
4. Optionally select **Render local dashboard** and inspect the result under
   `_site/assessment-years/2026/`.
5. Review `git diff`, then commit and push only when the records are ready to
   become public.

Do not enter confidential information in these trackers. The app is local, but
the saved CSV content becomes public if it is committed and pushed.
