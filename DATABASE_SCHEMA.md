# Supabase Database Schema Overview

## Core Tables

### 1. **accounts** (Chart of Accounts)
- Primary Key: `code` (VARCHAR 50)
- Hierarchical: `parent_code` references `accounts(code)`
- Nature: `debit` or `credit` only
- Flags: `is_transaction`, `require_cost_center`, `is_contra`, `is_parent`
- Level: Depth in hierarchy
- Unique ID: `id` (bigint)

### 2. **journal_entries** (Accounting Entries)
- Primary Key: `id` (serial)
- Unique: `entry_number` (VARCHAR 50)
- Status: `draft` | `posted` | `void`
- Fields: `entry_date`, `reference`, `description`
- Timestamps: `created_at`, `updated_at`

### 3. **journal_entry_lines** (Entry Details)
- Primary Key: `id` (serial)
- FK: `journal_entry_id` → `journal_entries(id)` [CASCADE]
- FK: `account_id` → `accounts(id)` [CASCADE]
- FK: `cost_center_id` → `cost_centers(id)`
- Fields: `debit` (numeric 15,2), `credit` (numeric 15,2), `description`
- Constraints: debit >= 0, credit >= 0

### 4. **vouchers** (Cash/Payment Vouchers)
- Primary Key: `id` (bigint)
- Unique: `voucher_number`
- Type: Text field (specify types)
- Date: `date` (default: CURRENT_DATE)
- Payment Method: `payment_method`
- FK: `treasury_account_id` → `accounts(code)`
- Check Fields: `check_no`, `check_due_date`, `check_status` (pending/collected), `check_collected_date`, `bank_name`
- FK: `linked_journal_entry_id` → `journal_entries(id)`
- FK: `created_by` → `auth.users(id)`

### 5. **voucher_lines** (Voucher Details)
- Primary Key: `id` (bigint)
- FK: `voucher_id` → `vouchers(id)` [CASCADE]
- FK: `account_id` → `accounts(id)` [CASCADE]
- FK: `cost_center_id` → `cost_centers(id)`
- Fields: `amount`, `description`

### 6. **cost_centers** (Cost Center Hierarchy)
- Primary Key: `id` (serial)
- Unique: `code`
- Hierarchical: `parent_code` → `cost_centers(code)`
- Active Flag: `is_active`

### 7. **cost_center_types**
- Primary Key: `id` (bigint)
- Unique: `code`
- Fields: `code`, `name_ar`, `name_en`, `is_active`

### 8. **currencies**
- Primary Key: `id` (bigint)
- Unique: `code`
- Fields: `code`, `name`, `exchange_rate`, `is_base`

### 9. **profiles** (User Profiles)
- Primary Key: `id` (UUID)
- FK: `id` → `auth.users(id)` [CASCADE]
- Role: `admin` | `accountant` | `viewer`
- Fields: `full_name`, `updated_at`

### 10. **permissions_def** (Permission Definitions)
- Primary Key: `code` (text)
- Fields: `code`, `description`, `module`

### 11. **user_permissions** (User-Permission Mapping)
- Primary Key: (`user_id`, `permission_code`)
- FK: `user_id` → `auth.users(id)` [CASCADE]
- FK: `permission_code` → `permissions_def(code)` [CASCADE]

### 12. **system_definitions** (System Configuration)
- Primary Key: `id` (bigint)
- FK: `type` → `definition_types(code)` [CASCADE]
- Fields: `type`, `name_ar`, `code`, `extra_data` (JSONB), `is_active`

### 13. **definition_types** (Definition Type Templates)
- Primary Key: `code` (text)
- Fields: `code`, `name_ar`, `field_config` (JSONB)

## Key Relationships

```
accounts (hierarchical)
├── journal_entry_lines → journal_entries
├── voucher_lines → vouchers
└── system_definitions (via code field)

cost_centers (hierarchical)
├── journal_entry_lines
└── voucher_lines

profiles → auth.users
├── user_permissions → permissions_def
└── (multiple modules: finance, inventory, etc.)

vouchers
├── voucher_lines → accounts
├── linked_journal_entry_id → journal_entries (optional)
└── created_by → auth.users
```

## Important Rules

1. **Double-Entry Bookkeeping**: Each journal entry must have debit = credit
2. **Account Nature**: Accounts are either 'debit' or 'credit' accounts
3. **Cost Center Requirement**: Some accounts require cost center allocation
4. **Voucher Types**: Currently not enum-constrained (need to define: Receipt, Disbursement, Bank, etc.)
5. **Check Tracking**: Cheques can be tracked via `check_status` (pending → collected)
6. **Status Workflow**: Entries: draft → posted → (optionally void)
7. **Journal Entry Linking**: Vouchers can optionally link to created journal entries

## Service Layer Mapping

**FinanceService** should handle:
- `getAccountByCode(code)` - Fetch account hierarchy
- `getAccountsByNature(nature)` - Filter accounts by debit/credit
- `getCostCenters()` - Fetch cost center hierarchy
- `createJournalEntry(...)` - Save with validation
- `createVoucher(...)` - Save with check validation
- `validateDoubleEntry(debit, credit)` - Ensure balanced

**Models needed** in `lib/core/models/`:
- Account (with parent hierarchy support)
- CostCenter (with parent hierarchy support)
- JournalEntry + JournalEntryLine
- Voucher + VoucherLine
- Permission + UserProfile
- Currency, Definition

---

**Last Updated**: December 20, 2025
**Source**: Supabase Schema Analysis
