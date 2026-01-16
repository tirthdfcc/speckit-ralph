# Ralph Wiggum Principles Audit

Проверка соответствия нашей реализации Ralph Loop 11 принципам из статьи [AI Hero](https://www.aihero.dev/11-tips-for-better-ralph-wiggums).

## ✅ Принцип 1: Ralph Is A Loop

**Статус**: ✅ **СООТВЕТСТВУЕТ**

**Что требуется**: Цикл, который повторяет одинаковый промпт, позволяя агенту выбирать задачи самостоятельно.

**Наша реализация**:

- ✅ `afk-ralph-claude.sh` и `afk-ralph-codex.sh` реализуют цикл
- ✅ Промпт одинаковый на каждой итерации (из `prompt-template.md`)
- ✅ Агент выбирает задачу: "Pick the next unchecked task. Prioritize higher priority stories and risky integration work."

**Доказательства**:

```bash
# afk-ralph-claude.sh, lines 122-132
for ((i=1; i<=ITERATIONS; i++)); do
  RALPH_ARTIFACT_DIR="$ARTIFACT_DIR" "$SCRIPT_DIR/ralph-once-claude.sh"
  check_promise
  sleep "${RALPH_SLEEP_SECONDS:-2}"
done
```

**Улучшения**: Не требуются.

---

## ✅ Принцип 2: Start With HITL, Then Go AFK

**Статус**: ✅ **СООТВЕТСТВУЕТ**

**Что требуется**: Два режима - HITL (human-in-the-loop) для обучения и AFK (away from keyboard) для автономной работы.

**Наша реализация**:

- ✅ HITL: `ralph-once-claude.sh`, `ralph-once-codex.sh`
- ✅ AFK: `afk-ralph-claude.sh`, `afk-ralph-codex.sh`
- ✅ AFK имеет ограничение итераций: `./afk-ralph-claude.sh <iterations>`
- ✅ Detach mode для фоновой работы: `--detach`

**Доказательства**:

```bash
# README.md documentation
## Quickstart
### Using Claude Code (Interactive) - HITL mode
./scripts/ralph/ralph-once-claude.sh

## AFK Loop - Autonomous mode
./scripts/ralph/afk-ralph-claude.sh 10
```

**Улучшения**: Не требуются.

---

## ✅ Принцип 3: Define The Scope

**Статус**: ✅ **СООТВЕТСТВУЕТ**

**Что требуется**: Четко определенный scope через TODO list, GitHub issues, или структурированный PRD.

**Наша реализация**:

- ✅ Используем `tasks.md` как источник задач
- ✅ Задачи в формате чекбоксов `[ ]` / `[x]`
- ✅ Четкий stop condition: `<promise>COMPLETE</promise>` когда все задачи выполнены
- ✅ Промпт явно ссылается на tasks.md: "Use {{TASKS}} as the source of truth"

**Доказательства**:

```markdown
# prompt-template.md, lines 25-28

## Task selection

- Use {{TASKS}} as the source of truth.
- Pick the next unchecked task. Prioritize higher priority stories and risky integration work.
- If a task is blocked, record why in {{PROGRESS_FILE}} and pick a different task.
```

**Текущий пример**: `specs/003-audit-fixes/tasks.md` содержит 38 задач с приоритетами и фазами.

**Улучшения**: Можно добавить поддержку JSON-формата с `passes: true/false` как в статье.

---

## ✅ Принцип 4: Track Ralph's Progress

**Статус**: ✅ **СООТВЕТСТВУЕТ**

**Что требуется**: Progress file для отслеживания выполненных задач между итерациями.

**Наша реализация**:

- ✅ `progress.txt` создается автоматически (ralph-env.sh, lines 44-55)
- ✅ Промпт требует обновления progress после каждой задачи
- ✅ Структура записи включает: Task ID, описание, решения, файлы, тесты, блокеры

**Доказательства**:

```markdown
# prompt-template.md, lines 38-43

5. Update {{PROGRESS_FILE}} with:
   - Task ID + short description
   - Decisions and rationale
   - Files changed
   - Tests run (with results)
   - Blockers or follow-ups
```

**Текущий пример**: `specs/003-audit-fixes/progress.txt` содержит детальные записи T001-T013.

**Улучшения**: Не требуются.

---

## ✅ Принцип 5: Use Feedback Loops

**Статус**: ✅ **СООТВЕТСТВУЕТ**

**Что требуется**: Обязательные проверки (types, tests, linting) перед коммитом.

**Наша реализация**:

- ✅ `ruff check .` - линтинг
- ✅ `ruff format --check .` - форматирование
- ✅ `pytest` - тесты (smallest relevant scope)
- ✅ Промпт требует прохождения всех проверок перед коммитом

**Доказательства**:

```markdown
# prompt-template.md, lines 34-37

4. Run feedback loops:
   - ruff check .
   - ruff format --check .
   - pytest for the touched tests or the smallest relevant scope
```

**Улучшения**:

- ⚠️ Можно добавить pre-commit hooks для автоматической блокировки плохих коммитов
- ⚠️ Можно добавить mypy/pyright для type checking (сейчас только Ruff)

---

## ✅ Принцип 6: Take Small Steps

**Статус**: ✅ **СООТВЕТСТВУЕТ**

**Что требуется**: Одна задача за итерацию, маленькие коммиты, частые feedback loops.

**Наша реализация**:

- ✅ Правило: "Work on EXACTLY ONE task per iteration"
- ✅ "Keep changes small and focused (one logical change per commit)"
- ✅ Feedback loops запускаются после каждой задачи, не в конце

**Доказательства**:

```markdown
# prompt-template.md, lines 18-23

## Non-negotiable rules

1. Read and follow {{REPO_ROOT}}/AGENTS.md.
2. Work on EXACTLY ONE task per iteration.
3. Keep changes small and focused (one logical change per commit).
4. Use feedback loops before committing.
5. Update progress log after each completed task.
```

**Улучшения**: Не требуются.

---

## ✅ Принцип 7: Prioritize Risky Tasks

**Статус**: ✅ **СООТВЕТСТВУЕТ**

**Что требуется**: Приоритет архитектурным решениям, интеграциям, и неизвестным задачам.

**Наша реализация**:

- ✅ Явная инструкция: "Prioritize higher priority stories and risky integration work"
- ✅ Задачи в tasks.md имеют метки приоритета (P0, P1, P2, P3)
- ✅ Агент выбирает задачу, а не просто берет первую

**Доказательства**:

```markdown
# prompt-template.md, line 27

- Pick the next unchecked task. Prioritize higher priority stories and risky integration work.
```

**Улучшения**:

- ⚠️ Можно добавить более детальную приоритизацию в промпт:
  ```markdown
  Prioritize in this order:

  1. Architectural decisions (P0)
  2. Integration points and risky work (P1)
  3. Standard features (P2)
  4. Polish and quick wins (P3)
  ```

---

## ⚠️ Принцип 8: Explicitly Define Software Quality

**Статус**: ⚠️ **ЧАСТИЧНО СООТВЕТСТВУЕТ**

**Что требуется**: Явные ожидания качества кода в AGENTS.md или промпте.

**Наша реализация**:

- ✅ AGENTS.md существует и содержит coding standards
- ✅ Промпт ссылается на AGENTS.md: "Read and follow {{REPO_ROOT}}/AGENTS.md"
- ⚠️ Но в AGENTS.md нет явного заявления о типе проекта (production vs prototype)
- ⚠️ Нет философского statement о качестве и долгосрочности кода

**Текущее состояние AGENTS.md**:

- ✅ Есть coding style guidelines
- ✅ Есть testing guidelines
- ⚠️ Нет statement "This is production code" или "Fight entropy"

**Улучшения**:

- ❗ Добавить секцию "Software Quality Philosophy" в AGENTS.md:

  ```markdown
  ## Software Quality Philosophy

  This is production code that will outlive any individual contributor.
  Every shortcut becomes technical debt. Every hack compounds into
  future burden. Fight entropy. Leave the codebase better than you found it.

  Standards:

  - Never use bare except: blocks
  - Type hints required for all public functions
  - Tests required for all user-facing functionality
  - Documentation required for all public APIs
  ```

---

## ❌ Принцип 9: Use Docker Sandboxes

**Статус**: ❌ **НЕ СООТВЕТСТВУЕТ**

**Что требуется**: Docker sandboxes для изоляции AFK Ralph от системных файлов.

**Наша реализация**:

- ❌ Используем `--dangerously-skip-permissions` вместо sandboxing
- ❌ Claude Code запускается с полным доступом к файловой системе
- ✅ Есть safety rules в промпте: "Do not run destructive commands"

**Доказательства**:

```bash
# ralph-once-claude.sh, line 44
--dangerously-skip-permissions \
```

**Риски**:

- Агент может случайно удалить важные файлы
- Нет изоляции от home directory и SSH keys
- Потенциально опасно для AFK режима

**Улучшения**:

- ❗ **КРИТИЧНО для AFK**: Добавить Docker sandbox support
- ❗ Создать `ralph-once-claude-docker.sh`:
  ```bash
  docker run --rm \
    -v "$(pwd):/workspace" \
    -w /workspace \
    claude-code-sandbox \
    claude --print "$(cat prompt.md)"
  ```
- Или использовать [firejail](https://firejail.wordpress.com/) для песочницы

**Временное решение**:

- Использовать HITL Ralph для критических операций
- Ограничить AFK Ralph небольшим числом итераций (5-10)
- Всегда проверять git diff после AFK запуска

---

## N/A Принцип 10: Pay To Play

**Статус**: N/A (не относится к реализации)

**Примечание**: Это экономический принцип, не технический. Наша реализация поддерживает:

- ✅ Claude Code API (платный)
- ✅ Codex (платный)
- ✅ Переменная RALPH_SLEEP_SECONDS для контроля rate limits

---

## ✅ Принцип 11: Make It Your Own

**Статус**: ✅ **СООТВЕТСТВУЕТ**

**Что требуется**: Гибкость конфигурации, альтернативные источники задач, кастомные выходы.

**Наша реализация**:

- ✅ Поддержка переменных окружения для кастомизации
- ✅ Опциональная GitHub интеграция (RALPH_GH_ISSUE, RALPH_GH_CREATE_PR)
- ✅ Гибкий промпт через template
- ✅ Поддержка разных AI CLI (Codex и Claude Code)

**Доказательства**:

```markdown
# prompt-template.md, lines 50-52

## GitHub integration (optional)

- If RALPH_GH_ISSUE is set and gh is available, comment a short summary on that issue.
- If RALPH_GH_CREATE_PR=1, open a PR at the end of the iteration.
```

**Возможные расширения**:

- 📝 Test Coverage Loop
- 📝 Linting Loop (у нас почти есть - 238 ошибок линтинга)
- 📝 Entropy Loop (code smells, dead code)

**Улучшения**: Можно добавить примеры альтернативных loop types в README.

---

## 📊 Итоговая оценка

| Принцип                               | Статус              | Приоритет улучшения    |
| ------------------------------------- | ------------------- | ---------------------- |
| 1. Ralph Is A Loop                    | ✅ Соответствует    | -                      |
| 2. Start With HITL, Then Go AFK       | ✅ Соответствует    | -                      |
| 3. Define The Scope                   | ✅ Соответствует    | Low (можно JSON)       |
| 4. Track Ralph's Progress             | ✅ Соответствует    | -                      |
| 5. Use Feedback Loops                 | ✅ Соответствует    | Low (pre-commit hooks) |
| 6. Take Small Steps                   | ✅ Соответствует    | -                      |
| 7. Prioritize Risky Tasks             | ✅ Соответствует    | Low (детализация)      |
| 8. Explicitly Define Software Quality | ⚠️ Частично         | **High**               |
| 9. Use Docker Sandboxes               | ❌ Не соответствует | **Critical for AFK**   |
| 10. Pay To Play                       | N/A                 | -                      |
| 11. Make It Your Own                  | ✅ Соответствует    | -                      |

**Общий балл**: 8/10 ✅

---

## 🚨 Критические улучшения

### 1. Docker Sandbox (Принцип 9) - КРИТИЧНО

**Проблема**: Используем `--dangerously-skip-permissions` без изоляции.

**Решение**:

```bash
# Создать scripts/ralph/ralph-once-claude-sandbox.sh
docker run --rm \
  -v "$(pwd):/workspace:rw" \
  -v "$ARTIFACT_DIR:/artifacts:rw" \
  -w /workspace \
  --network none \
  --read-only \
  --tmpfs /tmp \
  claude/sandbox:latest \
  claude --print "$(cat /artifacts/prompt.md)"
```

**Альтернатива**: Использовать [gVisor](https://gvisor.dev/) или firejail для syscall filtering.

### 2. Software Quality Statement (Принцип 8) - ВЫСОКИЙ ПРИОРИТЕТ

**Проблема**: Нет явного statement о качестве кода в AGENTS.md.

**Решение**: Добавить в AGENTS.md:

```markdown
## Software Quality Philosophy

**This is production code.** It will outlive any individual contributor.

### Principles

- Every shortcut becomes someone else's burden
- Every hack compounds into technical debt
- Fight entropy actively
- Leave the codebase better than you found it

### Non-Negotiables

- Type hints for all public functions
- Tests for all user-facing functionality
- No bare except: blocks without specific exception types
- No TODO comments without GitHub issue references
- No commented-out code in commits
```

---

## 📝 Рекомендуемые улучшения

### Low Priority

1. **Pre-commit hooks** (Принцип 5)
   - Блокировать коммиты с failing tests
   - Автоматический ruff format перед коммитом

2. **Детальная приоритизация** (Принцип 7)
   - Расширить промпт с явной иерархией приоритетов

3. **JSON PRD format** (Принцип 3)
   - Опциональная поддержка structured PRD с `passes: true/false`

### Future Enhancements

1. **Alternative Loop Types**
   - Test Coverage Loop (для достижения 80%+ coverage)
   - Entropy Loop (удаление dead code, дубликатов)
   - Linting Loop (238 ошибок → 0)

2. **GitHub Integration**
   - Автоматическое создание PR после завершения feature
   - Комментарии к issues после каждой задачи

---

## ✅ Следующие шаги

1. ❗ **НЕМЕДЛЕННО**: Добавить Software Quality Philosophy в AGENTS.md
2. ❗ **ПЕРЕД AFK**: Реализовать Docker sandbox для безопасности
3. 📝 Рассмотреть pre-commit hooks
4. 📝 Рассмотреть alternative loop types

**Verdict**: Наша реализация Ralph Loop соответствует 8 из 10 применимых принципов. Два критических улучшения (Software Quality + Docker Sandbox) сделают её production-ready.
