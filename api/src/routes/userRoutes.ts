import { Router } from "express";
import * as userController from "../controllers/userController";
import { authenticate } from "../middleware/auth";
import { handleValidation } from "../middleware/errorHandler";
import {
  changePasswordValidator,
  deleteAccountValidator,
  updateProfileValidator,
} from "../validators/userValidators";

const router = Router();

router.use(authenticate);

router.get("/me", userController.me);
router.put("/profile", updateProfileValidator, handleValidation, userController.updateProfile);
router.put(
  "/password",
  changePasswordValidator,
  handleValidation,
  userController.changePassword
);
router.post("/verify-email", userController.verifyEmail);
router.delete(
  "/account",
  deleteAccountValidator,
  handleValidation,
  userController.deleteAccount
);

export default router;
