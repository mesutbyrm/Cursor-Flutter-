import { Router } from "express";
import rateLimit from "express-rate-limit";
import * as authController from "../controllers/authController";
import { authenticate } from "../middleware/auth";
import { handleValidation } from "../middleware/errorHandler";
import {
  forgotPasswordValidator,
  loginValidator,
  refreshValidator,
  registerValidator,
  resetPasswordValidator,
} from "../validators/authValidators";

const router = Router();

router.use(
  rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 30,
    message: {
      success: false,
      error: {
        code: "RATE_LIMIT",
        message: "Çok fazla giriş denemesi.",
      },
    },
  })
);

router.post("/register", registerValidator, handleValidation, authController.register);
router.post("/login", loginValidator, handleValidation, authController.login);
router.post("/refresh", refreshValidator, handleValidation, authController.refresh);
router.post("/logout", authenticate, authController.logout);
router.post(
  "/forgot-password",
  forgotPasswordValidator,
  handleValidation,
  authController.forgotPassword
);
router.post(
  "/reset-password",
  resetPasswordValidator,
  handleValidation,
  authController.resetPassword
);

export default router;
