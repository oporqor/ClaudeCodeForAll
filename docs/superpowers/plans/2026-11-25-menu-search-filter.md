# ระบบค้นหาและกรองเมนู Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** เพิ่มช่องค้นหา ตัวกรองความเผ็ด และตัวกรองภาค ให้ทำงานร่วมกับหมวดเดิมใน `thai-food.html`

**Architecture:** เก็บสถานะตัวกรองเป็นตัวแปรระดับสคริปต์ (`query`, `currentSpice`, `currentRegion`) แล้วขยาย `isVisible(d)` ให้รวมทุกเงื่อนไข `render()` เป็นจุดเดียวที่ซ่อน/แสดงการ์ด อัปเดตจำนวนที่พบ และ empty state ปุ่มสุ่มเมนูใช้ `isVisible` อยู่แล้วจึงไม่ต้องแก้

**Tech Stack:** HTML/CSS/vanilla JS ไฟล์เดียว ไม่เพิ่มไลบรารี

**Spec:** `docs/superpowers/specs/2026-11-25-menu-search-filter-design.md`

## Global Constraints

- แก้เฉพาะ `thai-food.html`; ไม่แยกไฟล์, ไม่เพิ่มไลบรารี, ไม่เปลี่ยนโครงข้อมูลเมนู, ไม่เก็บคำค้นใน localStorage
- ข้อความบนหน้าเว็บใช้คำตาม GLOSSARY.md: **เมนู**, **หมวด**, **เมนูโปรด** (ห้ามใช้ ประเภท/หมวดหมู่/รายการโปรด/จาน)
- สร้าง DOM ด้วย `textContent` เท่านั้น ห้าม `innerHTML`
- ใช้ CSS variables เดิม (รองรับ dark mode); `<input>`/`<select>` ต้องมี `font: inherit; background: var(--surface); color: var(--text); border: 1px solid var(--border)` ไม่เช่นนั้นเป็นกล่องขาวใน dark mode; เพิ่ม `[hidden] { display: none !important; }` เพราะ `.btn` และคลาสอื่นตั้ง `display` ทับ attribute `hidden`, เลย์เอาต์ใช้ได้ที่ความกว้าง 360px, มี `:focus-visible` เหมือนปุ่มอื่น

## Review Focus

1. คำค้นมีช่องว่างหน้า/หลัง หรือเป็นช่องว่างล้วน → ตัดช่องว่างแล้วถือว่าไม่มีคำค้น
2. คำค้นมีอักขระพิเศษ regex เช่น `(`, `*`, `.` → ต้องไม่ error ใช้ `includes` ห้ามสร้าง RegExp
3. เลือกชิปเมนูโปรดโดยยังไม่มีเมนูโปรด → แสดงข้อความ "ยังไม่มีเมนูโปรด…" เดิมเท่านั้น ไม่แสดงข้อความ "ไม่พบเมนู" ซ้อน
4. ตัวกรองรวมกันแล้วไม่เหลือเมนู แล้วกดสุ่มเมนู → แสดง "ยังไม่มีเมนูให้สุ่ม" ไม่ error
5. ค้นหาแล้วเปลี่ยนหมวด/ภาค/ความเผ็ด → คำค้นยังอยู่ และจำนวนที่พบอัปเดตตามทันที; ล้างตัวกรองแล้วทุกอย่างกลับเป็นค่าเริ่มต้น

---

### Task 1: ช่องค้นหา + จำนวนที่พบ + empty state

**Files:**
- Modify: `thai-food.html` (CSS ใน `<style>`, toolbar ใน `<main>`, สคริปต์)

**Interfaces:**
- Produces: ตัวแปร `query: string` (ตัดช่องว่างและ lowercase แล้ว), ฟังก์ชัน `matchesQuery(d): boolean`, `resetFilters(): void`, `isVisible(d)` ที่รวม `matchesQuery`; องค์ประกอบ `#search` (input type=search พร้อม `<label>` ที่ซ่อนด้วยภาพ), `#searchClear` (ปุ่ม ✕), `#count` (ข้อความจำนวนที่พบ แยกจาก `#status`), `#noResults` (ข้อความ + ปุ่ม `#resetBtn` "ล้างตัวกรอง")

- [ ] **Step 1: เพิ่มช่องค้นหาเหนือชิปหมวดใน `.toolbar`** — `<input id="search" type="search" placeholder="ค้นหาเมนู เช่น ผัดไทย, curry">` พร้อม label "ค้นหาเมนู" และปุ่ม `#searchClear` ที่แสดงเมื่อมีคำค้นเท่านั้น (ซ่อนปุ่มล้างของเบราว์เซอร์ด้วย `input[type=search]::-webkit-search-cancel-button { -webkit-appearance: none; }` กันปุ่ม ✕ ซ้อนสองอัน); ใส่สไตล์ให้กว้างเต็มแถวบนมือถือ
- [ ] **Step 2: เขียน `matchesQuery(d)`** — คืน true ถ้า `query` ว่าง หรือ `d.th`, `d.en`, `d.desc`, `d.region` หรือ `d.cat` (lowercase) มี `query` เป็นสตริงย่อย; ผูก `input` event → ตั้ง `query = value.trim().toLowerCase()`, `clearPicked()`, ล้าง `#status` แล้ว `render()` (เหมือน `setCat`); Escape ใน input และปุ่ม ✕ ล้างคำค้นแล้วโฟกัสกลับที่ input
- [ ] **Step 3: ขยาย `isVisible(d)`** — ผลลัพธ์ = เงื่อนไขหมวดเดิม **และ** `matchesQuery(d)`
- [ ] **Step 4: อัปเดต `render()`** — เขียน "พบ N เมนู" ลง `#count` (ไม่ใช่ `#status`) เมื่อมีคำค้นหรือตัวกรองใดทำงานอยู่ และเว้นว่างเมื่อไม่มี — `#status` ใช้กับปุ่มสุ่มเมนูเท่านั้น เพื่อไม่ให้ `toggleFavorite` → `render()` ลบข้อความ "วันนี้กิน … ดีไหม?"; แสดง `#noResults` เมื่อไม่มีการ์ดที่มองเห็นและไม่ใช่กรณี Review Focus ข้อ 3 (เมนูโปรดว่างใช้ `#empty` เดิม); `#resetBtn` เรียก `resetFilters()` ซึ่งคืนค่า query, หมวด (`ALL_CAT`) และช่องค้นหาเป็นค่าเริ่มต้น
- [ ] **Step 5: ตรวจในเบราว์เซอร์** — เปิด `thai-food.html` แล้วยืนยัน: พิมพ์ `ผัด` เหลือ 3 เมนู (ผัดไทย, ผัดกะเพรา, ผัดซีอิ๊ว); `CURRY` เหลือ 2 (Green, Massaman); `อีสาน` เหลือ 2 (ค้นจากภาค); กดหัวใจหลังสุ่มเมนูแล้วข้อความ "วันนี้กิน…" ยังอยู่; `(` ไม่ error และแสดง "ไม่พบเมนู"; เว้นวรรคล้วนแสดงครบ 12; ชิปเมนูโปรดตอนว่างแสดงเฉพาะข้อความเดิม; สุ่มเมนูตอนไม่เหลือผลแสดง "ยังไม่มีเมนูให้สุ่ม"

### Task 2: ตัวกรองความเผ็ดและภาค

**Files:**
- Modify: `thai-food.html`

**Interfaces:**
- Consumes: `isVisible`, `render`, `resetFilters` จาก Task 1
- Produces: `currentSpice: string` (`"all"` หรือ `"0"`–`"3"` — ค่าจาก `<select>` เป็นสตริงเสมอ), `currentRegion: string` (ค่าเริ่มต้น `"all"`), `<select id="spiceFilter">` และ `<select id="regionFilter">` พร้อม label

- [ ] **Step 1: เพิ่ม `<select>` สองตัวใน toolbar** (ความเผ็ด: ทั้งหมด / ไม่เผ็ด / 🌶 / 🌶🌶 / 🌶🌶🌶 ตรงกับ `d.spice` 0–3; ภาค: ทั้งหมด + ภาคที่มีใน `dishes` สร้างจากข้อมูลด้วย `[...new Set(dishes.map(d => d.region))]` ไม่พิมพ์ซ้ำเอง) ใช้ `<option>` ผ่าน `textContent`
- [ ] **Step 2: ผูก `change` → อัปเดตตัวแปร แล้ว `clearPicked()`, ล้าง `#status`, `render()`**
- [ ] **Step 3: ขยาย `isVisible(d)`** ให้ต้องผ่านทั้งความเผ็ดและภาคด้วย โดยความเผ็ดเช็คเป็น `currentSpice === "all" || d.spice === Number(currentSpice)` (ห้ามใช้ truthy check เพราะ "ไม่เผ็ด" = 0 เป็น falsy และห้ามเทียบ `===` กับสตริงตรง ๆ); ขยาย `resetFilters()` ให้คืนค่า `<select>` ทั้งสอง; ขยายเงื่อนไข "มีตัวกรองทำงานอยู่" ใน `render()` ให้นับสองตัวนี้
- [ ] **Step 4: ตรวจในเบราว์เซอร์** — ภาคอีสาน = 2 เมนู (ส้มตำ, ลาบหมู); 🌶🌶🌶 = 4; ไม่เผ็ด = 2 (ข้าวเหนียวมะม่วง, ขนมครก); ภาคอีสาน + 🌶🌶🌶 + คำค้น `ลาบ` = 1; หมวดยำ-ตำ + ภาคใต้ = ไม่พบ → "ล้างตัวกรอง" คืนครบ 12 และรีเซ็ตทุกช่อง; ที่ความกว้าง 360px ไม่มี scroll แนวนอน; dark mode อ่านออก
- [ ] **Step 5: ปรับ `task.md`** — เพิ่มหัวข้อ "7. ค้นหาและกรอง" ในรายการงานพร้อมติ๊กเสร็จตามที่ทำจริง

---

**Self-review:** ครบทุกข้อใน spec (ค้นหา, ✕, ความเผ็ด, ภาค, รวมแบบ "และ", จำนวนที่พบ, empty+ล้าง, สุ่มจากผลที่กรอง, GLOSSARY) · ชื่อ `isVisible/resetFilters/query/currentSpice/currentRegion` ตรงกันทั้งสอง Task · Review Focus ทั้ง 5 ข้อมีจุดตรวจใน Step 5 ของ Task 1 และ Step 4 ของ Task 2 · ไม่มีเฟรมเวิร์กทดสอบในโปรเจกต์และไม่ได้อยู่ใน git จึงใช้การตรวจในเบราว์เซอร์แทน test และไม่มีขั้น commit

**วิธีตรวจ:** เครื่องมี Node และ Google Chrome — ลองสคริปต์ตรวจแบบ headless (เช่น `puppeteer-core` ชี้ไปที่ Chrome ติดตั้งในโฟลเดอร์ scratchpad ไม่ใช่โปรเจกต์) ที่ตั้งค่าช่องค้นหา/`<select>` แล้วนับการ์ดที่ไม่มีคลาส `hidden`; ถ้าติดตั้งไม่ได้ ให้รายงานผู้ใช้ว่ารายการตรวจเป็นแบบ manual และห้ามรายงานว่า "ผ่าน" โดยไม่ได้รันจริง
