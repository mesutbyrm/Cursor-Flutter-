import { body } from "express-validator";

export const updateProfileValidator = [
  body("name").optional().trim().isLength({ min: 2, max: 120 }),
  body("phone").optional({ values: "null" }).isMobilePhone("any"),
  body("avatarUrl").optional({ values: "null" }).isURL().withMessage("Geçerli bir URL girin."),
];

export const changePasswordValidator = [
  body("currentPassword").notEmpty(),
  body("newPassword").isLength({ min: 8 }),
];

export const deleteAccountValidator = [
  body("password").notEmpty(),
];
