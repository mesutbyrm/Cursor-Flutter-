import { body } from "express-validator";

export const registerValidator = [
  body("email").isEmail().normalizeEmail().withMessage("Geçerli bir e-posta girin."),
  body("password")
    .isLength({ min: 8 })
    .withMessage("Şifre en az 8 karakter olmalıdır."),
  body("name").trim().isLength({ min: 2, max: 120 }).withMessage("İsim 2-120 karakter olmalıdır."),
  body("phone").optional({ values: "null" }).isMobilePhone("any").withMessage("Geçerli bir telefon numarası girin."),
];

export const loginValidator = [
  body("email").isEmail().normalizeEmail(),
  body("password").notEmpty(),
];

export const refreshValidator = [
  body("refreshToken").notEmpty().withMessage("refreshToken gerekli."),
];

export const forgotPasswordValidator = [
  body("email").isEmail().normalizeEmail(),
];

export const resetPasswordValidator = [
  body("token").notEmpty(),
  body("password").isLength({ min: 8 }).withMessage("Şifre en az 8 karakter olmalıdır."),
];
