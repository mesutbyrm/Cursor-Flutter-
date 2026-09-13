--
-- PostgreSQL database dump
--

\restrict lzD4s4usSR9D2o3dlL59I8JLnTd35JmNe5VtdYVfU1ovKZHY7a6C89wMFEC007I

-- Dumped from database version 17.9 (Ubuntu 17.9-1.pgdg24.04+1)
-- Dumped by pg_dump version 17.11 (Debian 17.11-1.pgdg12+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS '';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account_deletions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_deletions (
    id text NOT NULL,
    "userId" text NOT NULL,
    "originalEmail" text,
    "originalUsername" text,
    reason text,
    source text DEFAULT 'mobile'::text NOT NULL,
    status text DEFAULT 'completed'::text NOT NULL,
    "requestedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "completedAt" timestamp(3) without time zone
);


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id text NOT NULL,
    "userId" text NOT NULL,
    type text NOT NULL,
    provider text NOT NULL,
    "providerAccountId" text NOT NULL,
    refresh_token text,
    access_token text,
    expires_at integer,
    token_type text,
    scope text,
    id_token text,
    session_state text
);


--
-- Name: achievements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.achievements (
    id text NOT NULL,
    code text NOT NULL,
    "nameTr" text NOT NULL,
    "nameEn" text NOT NULL,
    "descriptionTr" text NOT NULL,
    "descriptionEn" text NOT NULL,
    icon text NOT NULL,
    category text NOT NULL,
    "targetValue" integer NOT NULL,
    "rewardCredits" integer DEFAULT 0 NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: activity_feed_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_feed_config (
    id text NOT NULL,
    "isEnabled" boolean DEFAULT true NOT NULL,
    "maxItems" integer DEFAULT 20 NOT NULL,
    "visibleToGuests" boolean DEFAULT true NOT NULL,
    "visibleToBasic" boolean DEFAULT true NOT NULL,
    "visibleToPremium" boolean DEFAULT true NOT NULL,
    "visibleToGold" boolean DEFAULT true NOT NULL,
    "visibleToDiamond" boolean DEFAULT true NOT NULL,
    "visibleToModerator" boolean DEFAULT true NOT NULL,
    "visibleToAdmin" boolean DEFAULT true NOT NULL,
    "specificUserIds" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: ad_networks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ad_networks (
    id text NOT NULL,
    name text NOT NULL,
    provider text NOT NULL,
    "adCode" text,
    "adUnitId" text,
    "appId" text,
    "isActive" boolean DEFAULT false NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: ad_placements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ad_placements (
    id text NOT NULL,
    "placementKey" text NOT NULL,
    name text NOT NULL,
    description text,
    "adNetworkId" text,
    "adType" text DEFAULT 'banner'::text NOT NULL,
    "position" text,
    platform text DEFAULT 'all'::text NOT NULL,
    "isActive" boolean DEFAULT false NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "customCode" text,
    targeting jsonb,
    "frequencyCap" integer DEFAULT 0 NOT NULL,
    impressions integer DEFAULT 0 NOT NULL,
    clicks integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: admin_popups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_popups (
    id text NOT NULL,
    title text NOT NULL,
    message text NOT NULL,
    buttons text DEFAULT '[]'::text NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "showTo" text DEFAULT 'all'::text NOT NULL,
    "popupType" text DEFAULT 'custom'::text NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    "maxShowCount" integer DEFAULT 1 NOT NULL,
    "showOnRefresh" boolean DEFAULT false NOT NULL,
    "showDelaySeconds" integer DEFAULT 1 NOT NULL,
    "lastSentAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: admin_user_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_user_actions (
    id text NOT NULL,
    "targetUserId" text NOT NULL,
    "adminId" text NOT NULL,
    "adminName" text,
    action text NOT NULL,
    "oldValue" text,
    "newValue" text,
    reason text,
    metadata text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: agencies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agencies (
    id text NOT NULL,
    name text NOT NULL,
    description text,
    "ownerId" text NOT NULL,
    "ownerName" text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    "commissionRate" double precision DEFAULT 5.0 NOT NULL,
    "contactEmail" text,
    "contactPhone" text,
    "logoUrl" text,
    "totalEarnings" double precision DEFAULT 0 NOT NULL,
    "totalMembers" integer DEFAULT 0 NOT NULL,
    "activeMembers" integer DEFAULT 0 NOT NULL,
    "performanceScore" double precision DEFAULT 0 NOT NULL,
    "penaltyLevel" integer DEFAULT 0 NOT NULL,
    "penaltyNote" text,
    "invitesDisabled" boolean DEFAULT false NOT NULL,
    "approvedAt" timestamp(3) without time zone,
    "rejectedAt" timestamp(3) without time zone,
    "rejectedReason" text,
    "suspendedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    level text DEFAULT 'bronze'::text NOT NULL
);


--
-- Name: agency_bonus_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agency_bonus_rules (
    id text NOT NULL,
    level text NOT NULL,
    label text NOT NULL,
    "bonusRate" double precision DEFAULT 0 NOT NULL,
    "minMonthlyEarning" double precision DEFAULT 0 NOT NULL,
    "minActiveBroadcasters" integer DEFAULT 0 NOT NULL,
    "minStreamMinutes" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: agency_commission_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agency_commission_rules (
    id text NOT NULL,
    "agencyId" text,
    "sourceType" text NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    rate double precision,
    note text,
    "updatedById" text,
    "updatedByName" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: agency_earnings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agency_earnings (
    id text NOT NULL,
    "agencyId" text NOT NULL,
    "userId" text NOT NULL,
    amount double precision NOT NULL,
    "sourceType" text NOT NULL,
    "sourceId" text,
    "originalAmount" double precision NOT NULL,
    "commissionRate" double precision NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: agency_leave_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agency_leave_requests (
    id text NOT NULL,
    "agencyId" text NOT NULL,
    "userId" text NOT NULL,
    reason text,
    status text DEFAULT 'pending'::text NOT NULL,
    "reviewedBy" text,
    "reviewNote" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "reviewedAt" timestamp(3) without time zone
);


--
-- Name: agency_penalties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agency_penalties (
    id text NOT NULL,
    "agencyId" text NOT NULL,
    level integer NOT NULL,
    reason text NOT NULL,
    "appliedBy" text,
    "isActive" boolean DEFAULT true NOT NULL,
    "resolvedAt" timestamp(3) without time zone,
    "resolvedBy" text,
    "resolvedNote" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: agency_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agency_tasks (
    id text NOT NULL,
    "agencyId" text NOT NULL,
    "weekStart" timestamp(3) without time zone NOT NULL,
    "weekEnd" timestamp(3) without time zone NOT NULL,
    "earningsTarget" double precision DEFAULT 0 NOT NULL,
    "newUsersTarget" integer DEFAULT 0 NOT NULL,
    "activeUsersTarget" integer DEFAULT 0 NOT NULL,
    "earningsActual" double precision DEFAULT 0 NOT NULL,
    "newUsersActual" integer DEFAULT 0 NOT NULL,
    "activeUsersActual" integer DEFAULT 0 NOT NULL,
    "completionPercent" double precision DEFAULT 0 NOT NULL,
    "bonusAwarded" double precision DEFAULT 0 NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: agency_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agency_users (
    id text NOT NULL,
    "agencyId" text NOT NULL,
    "userId" text NOT NULL,
    role text DEFAULT 'member'::text NOT NULL,
    "joinedVia" text,
    "inviteCodeId" text,
    "totalEarnings" double precision DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "joinedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "leftAt" timestamp(3) without time zone,
    "joinIp" text,
    "joinDeviceId" text
);


--
-- Name: agency_wallet_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agency_wallet_transactions (
    id text NOT NULL,
    "agencyId" text NOT NULL,
    type text NOT NULL,
    direction text NOT NULL,
    amount double precision NOT NULL,
    "balanceBefore" double precision NOT NULL,
    "balanceAfter" double precision NOT NULL,
    "tlAmount" double precision,
    "rateUsed" double precision,
    "bonusRate" double precision,
    "targetUserId" text,
    "targetUserName" text,
    "actorId" text,
    "actorName" text,
    "actorRole" text,
    reason text,
    "referenceType" text,
    "referenceId" text,
    "idempotencyKey" text,
    metadata text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: agency_wallets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agency_wallets (
    id text NOT NULL,
    "agencyId" text NOT NULL,
    "jetonBalance" double precision DEFAULT 0 NOT NULL,
    "totalTopUp" double precision DEFAULT 0 NOT NULL,
    "totalBonus" double precision DEFAULT 0 NOT NULL,
    "totalTransferred" double precision DEFAULT 0 NOT NULL,
    "totalAdjusted" double precision DEFAULT 0 NOT NULL,
    "isLocked" boolean DEFAULT false NOT NULL,
    "lockReason" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: animation_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.animation_assignments (
    id text NOT NULL,
    "userId" text NOT NULL,
    "animationId" text NOT NULL,
    "assignmentType" text DEFAULT 'user_custom'::text NOT NULL,
    context text,
    category text,
    "startDate" timestamp(3) without time zone,
    "endDate" timestamp(3) without time zone,
    priority integer DEFAULT 50 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "assignedBy" text,
    note text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: animation_membership_defaults; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.animation_membership_defaults (
    id text NOT NULL,
    "membershipTier" text NOT NULL,
    category text NOT NULL,
    "animationId" text NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: animation_playback_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.animation_playback_logs (
    id text NOT NULL,
    "userId" text,
    "animationId" text NOT NULL,
    "roomId" text,
    context text,
    "playedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: animations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.animations (
    id text NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    category text NOT NULL,
    type text NOT NULL,
    "assetUrl" text NOT NULL,
    "thumbnailUrl" text,
    "previewUrl" text,
    "soundUrl" text,
    "durationMs" integer DEFAULT 3000 NOT NULL,
    priority integer DEFAULT 10 NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    rarity text DEFAULT 'normal'::text NOT NULL,
    "membershipLevel" text,
    contexts jsonb,
    "position" text DEFAULT 'center'::text NOT NULL,
    scale text DEFAULT 'medium'::text NOT NULL,
    anchor text DEFAULT 'room'::text NOT NULL,
    "cooldownMs" integer DEFAULT 0 NOT NULL,
    "canSkip" boolean DEFAULT true NOT NULL,
    "activeFrom" timestamp(3) without time zone,
    "activeTo" timestamp(3) without time zone,
    "legacyType" text,
    "legacyRefId" text,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    metadata jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: anonymous_fortunes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.anonymous_fortunes (
    id text NOT NULL,
    "anonymousUserId" text NOT NULL,
    "fortuneType" text NOT NULL,
    "inputData" text NOT NULL,
    "aiResponse" text NOT NULL,
    language text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: anonymous_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.anonymous_users (
    id text NOT NULL,
    username text NOT NULL,
    "deviceId" text NOT NULL,
    credits integer DEFAULT 0 NOT NULL,
    "adsWatched" integer DEFAULT 0 NOT NULL,
    "adsWatchedToday" integer DEFAULT 0 NOT NULL,
    "lastAdDate" timestamp(3) without time zone,
    "fortunesUsed" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id text NOT NULL,
    "actorId" text NOT NULL,
    "actorRole" text,
    "actorIp" text,
    action text NOT NULL,
    "targetType" text,
    "targetId" text,
    before jsonb,
    after jsonb,
    description text,
    metadata jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: avatar_accessories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.avatar_accessories (
    id text NOT NULL,
    name text NOT NULL,
    slot text DEFAULT 'hat'::text NOT NULL,
    "assetUrl" text NOT NULL,
    tier text DEFAULT 'gold'::text NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: bana_ozel_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bana_ozel_history (
    id text NOT NULL,
    "userId" text NOT NULL,
    "itemSlug" text NOT NULL,
    content text NOT NULL,
    "jetonSpent" integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: bana_ozel_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bana_ozel_items (
    id text NOT NULL,
    slug text NOT NULL,
    "nameTr" text NOT NULL,
    "nameEn" text NOT NULL,
    "descTr" text,
    "descEn" text,
    icon text NOT NULL,
    "jetonCost" integer DEFAULT 5 NOT NULL,
    category text DEFAULT 'fortune'::text NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "contentPool" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: blog_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blog_categories (
    id text NOT NULL,
    slug text NOT NULL,
    "nameTr" text NOT NULL,
    "nameEn" text DEFAULT ''::text NOT NULL,
    "descTr" text DEFAULT ''::text NOT NULL,
    "descEn" text DEFAULT ''::text NOT NULL,
    icon text DEFAULT 'BookOpen'::text NOT NULL,
    color text DEFAULT '#8B5CF6'::text NOT NULL,
    "coverImage" text DEFAULT ''::text NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "postCount" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: blog_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blog_comments (
    id text NOT NULL,
    "postId" text NOT NULL,
    "userId" text NOT NULL,
    "userName" text DEFAULT 'Anonim'::text NOT NULL,
    "userAvatar" text DEFAULT ''::text NOT NULL,
    content text NOT NULL,
    "isApproved" boolean DEFAULT true NOT NULL,
    likes integer DEFAULT 0 NOT NULL,
    "parentId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: blog_favorites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blog_favorites (
    id text NOT NULL,
    "postId" text NOT NULL,
    "userId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: blog_likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blog_likes (
    id text NOT NULL,
    "postId" text NOT NULL,
    "userId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: blog_posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blog_posts (
    id text NOT NULL,
    slug text NOT NULL,
    "titleTr" text NOT NULL,
    "titleEn" text DEFAULT ''::text NOT NULL,
    "descTr" text NOT NULL,
    "descEn" text DEFAULT ''::text NOT NULL,
    "contentTr" text NOT NULL,
    "contentEn" text DEFAULT ''::text NOT NULL,
    category text DEFAULT 'genel'::text NOT NULL,
    keywords text[] DEFAULT ARRAY[]::text[],
    "metaDescription" text DEFAULT ''::text NOT NULL,
    "coverImage" text DEFAULT ''::text NOT NULL,
    "readTime" integer DEFAULT 5 NOT NULL,
    views integer DEFAULT 0 NOT NULL,
    likes integer DEFAULT 0 NOT NULL,
    "isPublished" boolean DEFAULT false NOT NULL,
    "isFeatured" boolean DEFAULT false NOT NULL,
    "isTrending" boolean DEFAULT false NOT NULL,
    "isEditorPick" boolean DEFAULT false NOT NULL,
    "isAiGenerated" boolean DEFAULT false NOT NULL,
    "isPremium" boolean DEFAULT false NOT NULL,
    "zodiacSign" text DEFAULT ''::text NOT NULL,
    "authorId" text,
    "authorName" text DEFAULT 'Canlifal Editör'::text NOT NULL,
    "publishedAt" timestamp(3) without time zone,
    "scheduledAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: bot_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bot_profiles (
    id text NOT NULL,
    "userId" text NOT NULL,
    personality text NOT NULL,
    age integer NOT NULL,
    city text NOT NULL,
    interests text,
    "activityLevel" text DEFAULT 'medium'::text NOT NULL,
    "activeHoursStart" integer DEFAULT 9 NOT NULL,
    "activeHoursEnd" integer DEFAULT 23 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "lastActionAt" timestamp(3) without time zone,
    "totalActions" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: broadcast_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.broadcast_images (
    id text NOT NULL,
    name text NOT NULL,
    "imageUrl" text NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: celebrities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.celebrities (
    id text NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    category text NOT NULL,
    bio text,
    "profileImage" text,
    "coverImage" text,
    "isVerified" boolean DEFAULT true NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "followerCount" integer DEFAULT 0 NOT NULL,
    "birthDate" timestamp(3) without time zone,
    "birthPlace" text,
    "zodiacSign" text,
    "socialLinks" text,
    achievements text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: celebrity_follows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.celebrity_follows (
    id text NOT NULL,
    "userId" text NOT NULL,
    "celebrityId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: celebrity_post_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.celebrity_post_comments (
    id text NOT NULL,
    "postId" text NOT NULL,
    "userId" text NOT NULL,
    content text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: celebrity_post_likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.celebrity_post_likes (
    id text NOT NULL,
    "postId" text NOT NULL,
    "userId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: celebrity_posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.celebrity_posts (
    id text NOT NULL,
    "celebrityId" text NOT NULL,
    platform text NOT NULL,
    "postType" text DEFAULT 'photo'::text NOT NULL,
    content text,
    "mediaUrl" text,
    "externalUrl" text,
    "likeCount" integer DEFAULT 0 NOT NULL,
    "commentCount" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "isPinned" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: cfc_contests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cfc_contests (
    id text NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    description text,
    type text NOT NULL,
    scope text DEFAULT 'general'::text NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    "seasonId" text,
    "scoringMetrics" text NOT NULL,
    "commissionRate" double precision,
    rules text,
    "minParticipants" integer DEFAULT 2 NOT NULL,
    "maxParticipants" integer,
    "entryRequirements" text,
    "startsAt" timestamp(3) without time zone,
    "endsAt" timestamp(3) without time zone,
    "registrationEndsAt" timestamp(3) without time zone,
    rewards text,
    "createdBy" text,
    "isPublic" boolean DEFAULT true NOT NULL,
    "isFeatured" boolean DEFAULT false NOT NULL,
    "bannerImage" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: cfc_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cfc_participants (
    id text NOT NULL,
    "contestId" text NOT NULL,
    "userId" text,
    "agencyId" text,
    "roomId" text,
    "teamId" text,
    "displayName" text,
    score double precision DEFAULT 0 NOT NULL,
    rank integer,
    status text DEFAULT 'active'::text NOT NULL,
    "joinedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: cfc_payment_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cfc_payment_requests (
    id text NOT NULL,
    "userId" text NOT NULL,
    amount integer NOT NULL,
    method text NOT NULL,
    "senderInfo" text,
    notes text,
    status text DEFAULT 'pending'::text NOT NULL,
    "reviewedBy" text,
    "reviewNote" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: cfc_score_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cfc_score_logs (
    id text NOT NULL,
    "contestId" text NOT NULL,
    "userId" text,
    "agencyId" text,
    "roomId" text,
    metric text NOT NULL,
    delta double precision NOT NULL,
    reason text,
    "calculatedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: cfc_seasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cfc_seasons (
    id text NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    description text,
    "startsAt" timestamp(3) without time zone,
    "endsAt" timestamp(3) without time zone,
    "isActive" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: cfc_teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cfc_teams (
    id text NOT NULL,
    "contestId" text NOT NULL,
    name text NOT NULL,
    color text,
    "badgeEmoji" text,
    "captainId" text,
    "totalScore" double precision DEFAULT 0 NOT NULL,
    rank integer,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: chat_bans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_bans (
    id text NOT NULL,
    "roomId" text NOT NULL,
    "userId" text NOT NULL,
    "bannedBy" text NOT NULL,
    reason text,
    "expiresAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: chat_bubble_skins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_bubble_skins (
    id text NOT NULL,
    name text NOT NULL,
    "assetUrl" text NOT NULL,
    tier text DEFAULT 'gold'::text NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: chat_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_messages (
    id text NOT NULL,
    "roomId" text NOT NULL,
    "userId" text NOT NULL,
    content text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: chat_mutes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_mutes (
    id text NOT NULL,
    "roomId" text NOT NULL,
    "userId" text NOT NULL,
    "mutedBy" text NOT NULL,
    reason text,
    "expiresAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: chat_presences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_presences (
    id text NOT NULL,
    "roomId" text NOT NULL,
    "userId" text NOT NULL,
    nickname text,
    "isTyping" boolean DEFAULT false NOT NULL,
    "lastTyping" timestamp(3) without time zone,
    "lastSeen" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "seatIndex" integer DEFAULT '-1'::integer NOT NULL
);


--
-- Name: chat_room_gifts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_room_gifts (
    id text NOT NULL,
    "roomId" text NOT NULL,
    "senderId" text NOT NULL,
    "recipientId" text NOT NULL,
    "giftTypeId" text NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    "totalPrice" integer NOT NULL,
    "currencyType" text DEFAULT 'jeton'::text NOT NULL,
    "commissionAmount" integer DEFAULT 0 NOT NULL,
    "beneficiaryId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: chat_rooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_rooms (
    id text NOT NULL,
    slug text NOT NULL,
    "nameEn" text NOT NULL,
    "nameTr" text NOT NULL,
    "descEn" text NOT NULL,
    "descTr" text NOT NULL,
    icon text NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "isMuted" boolean DEFAULT false NOT NULL,
    "ownerId" text,
    "giftCommissionPercent" integer DEFAULT 0 NOT NULL,
    "giftBeneficiaryId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "backgroundImage" text,
    "currentMusicStartedAt" timestamp(3) without time zone,
    "currentMusicTitle" text,
    "currentMusicVideoId" text,
    "bannedWords" text,
    "activeDjId" text,
    "djUserIds" text,
    "whitelistedWords" text,
    "currentMusicDuration" text,
    "bannerImage" text,
    password text,
    "pinnedAnnouncement" text,
    "roomType" text DEFAULT 'FREE'::text NOT NULL,
    tags text,
    "welcomeMessage" text,
    "seatCount" integer,
    "isVipLounge" boolean DEFAULT false NOT NULL,
    "minMembershipTier" text,
    "showVipEntranceFx" boolean DEFAULT true NOT NULL,
    "vipThemeId" text
);


--
-- Name: chat_speak_blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_speak_blocks (
    id text NOT NULL,
    "roomId" text NOT NULL,
    "userId" text NOT NULL,
    "blockedBy" text NOT NULL,
    reason text,
    "expiresAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: chat_speak_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_speak_requests (
    id text NOT NULL,
    "roomId" text NOT NULL,
    "userId" text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    message text,
    reason text,
    "handledBy" text,
    "handledAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: chat_user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_user_roles (
    id text NOT NULL,
    "roomId" text NOT NULL,
    "userId" text NOT NULL,
    role text NOT NULL,
    "grantedBy" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversations (
    id text NOT NULL,
    "user1Id" text NOT NULL,
    "user2Id" text NOT NULL,
    "lastMessageAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "lastMessageText" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: credit_packages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credit_packages (
    id text NOT NULL,
    name text NOT NULL,
    "nameEn" text,
    credits integer NOT NULL,
    price double precision NOT NULL,
    currency text DEFAULT 'TRY'::text NOT NULL,
    "stripePriceId" text,
    "isActive" boolean DEFAULT true NOT NULL,
    "isFeatured" boolean DEFAULT false NOT NULL,
    "bonusCredits" integer DEFAULT 0 NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: credit_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credit_transactions (
    id text NOT NULL,
    "userId" text NOT NULL,
    amount integer NOT NULL,
    type text NOT NULL,
    description text,
    "relatedId" text,
    balance integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: currency_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.currency_config (
    id text NOT NULL,
    area text NOT NULL,
    "areaName" text NOT NULL,
    "currencyType" text DEFAULT 'cfc'::text NOT NULL,
    cost integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: custom_badges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_badges (
    id text NOT NULL,
    name text NOT NULL,
    icon text NOT NULL,
    color text DEFAULT '#fbbf24'::text NOT NULL,
    "bgColor" text DEFAULT '#78350f'::text NOT NULL,
    description text,
    tier text,
    "userId" text,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: daily_login_rewards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_login_rewards (
    id text NOT NULL,
    "userId" text NOT NULL,
    "rewardDate" date NOT NULL,
    streak integer DEFAULT 1 NOT NULL,
    "xpEarned" integer DEFAULT 10 NOT NULL,
    "jetonEarned" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: daily_quests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_quests (
    id text NOT NULL,
    "userId" text NOT NULL,
    "questDate" date NOT NULL,
    "questType" text NOT NULL,
    progress integer DEFAULT 0 NOT NULL,
    target integer DEFAULT 1 NOT NULL,
    reward integer DEFAULT 10 NOT NULL,
    claimed boolean DEFAULT false NOT NULL,
    "claimedAt" timestamp(3) without time zone
);


--
-- Name: daily_rewards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_rewards (
    id text NOT NULL,
    "userId" text NOT NULL,
    "rewardDate" date NOT NULL,
    streak integer DEFAULT 1 NOT NULL,
    "jetonReward" integer DEFAULT 5 NOT NULL,
    "claimedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: daily_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_tasks (
    id text NOT NULL,
    "userId" text NOT NULL,
    "taskType" text NOT NULL,
    "completedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "jetonEarned" integer DEFAULT 0 NOT NULL,
    date date NOT NULL
);


--
-- Name: direct_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.direct_messages (
    id text NOT NULL,
    "senderId" text NOT NULL,
    "receiverId" text NOT NULL,
    content text NOT NULL,
    "imageUrl" text,
    "isRead" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: dream_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dream_comments (
    id text NOT NULL,
    content text NOT NULL,
    "userId" text NOT NULL,
    "dreamId" text NOT NULL,
    "experienceType" text DEFAULT 'yorum'::text NOT NULL,
    "didComeTrue" boolean,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: dream_contest_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dream_contest_entries (
    id text NOT NULL,
    "contestId" text NOT NULL,
    "userId" text NOT NULL,
    interpretation text NOT NULL,
    "voteCount" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: dream_contest_votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dream_contest_votes (
    id text NOT NULL,
    "entryId" text NOT NULL,
    "userId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: dream_contests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dream_contests (
    id text NOT NULL,
    title text NOT NULL,
    description text NOT NULL,
    "dreamPrompt" text NOT NULL,
    "startDate" timestamp(3) without time zone NOT NULL,
    "endDate" timestamp(3) without time zone NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: dream_diary_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dream_diary_entries (
    id text NOT NULL,
    "userId" text NOT NULL,
    "dreamDate" date NOT NULL,
    title text NOT NULL,
    content text NOT NULL,
    symbols text[] DEFAULT ARRAY[]::text[],
    mood text,
    lucidity integer,
    "aiAnalysis" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: dream_favorites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dream_favorites (
    id text NOT NULL,
    "userId" text NOT NULL,
    "dreamId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: dream_interpretations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dream_interpretations (
    id text NOT NULL,
    title text NOT NULL,
    slug text NOT NULL,
    content text NOT NULL,
    summary text,
    keywords text[] DEFAULT ARRAY[]::text[],
    "metaDescription" text,
    category text DEFAULT 'genel'::text NOT NULL,
    views integer DEFAULT 0 NOT NULL,
    "isPublished" boolean DEFAULT true NOT NULL,
    "isAiGenerated" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: dream_symbols; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dream_symbols (
    id text NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    letter text NOT NULL,
    meaning text NOT NULL,
    "detailedMeaning" text,
    "relatedSymbols" text[] DEFAULT ARRAY[]::text[],
    "isPublished" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: dream_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dream_views (
    id text NOT NULL,
    "userId" text NOT NULL,
    "dreamId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: effect_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.effect_rules (
    id text NOT NULL,
    key text NOT NULL,
    name text NOT NULL,
    description text,
    "effectType" text NOT NULL,
    "effectRefId" text,
    "conditionType" text NOT NULL,
    threshold integer DEFAULT 0 NOT NULL,
    "conditionValue" text,
    "isActive" boolean DEFAULT true NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    metadata jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: email_verification_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_verification_tokens (
    id text NOT NULL,
    "userId" text NOT NULL,
    email text NOT NULL,
    token text NOT NULL,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    used boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: emoji_packs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emoji_packs (
    id text NOT NULL,
    name text NOT NULL,
    "coverUrl" text NOT NULL,
    emojis text NOT NULL,
    tier text DEFAULT 'gold'::text NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: entrance_effects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entrance_effects (
    id text NOT NULL,
    name text NOT NULL,
    "assetUrl" text NOT NULL,
    "assetType" text DEFAULT 'lottie'::text NOT NULL,
    tier text DEFAULT 'gold'::text NOT NULL,
    "durationMs" integer DEFAULT 3000 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "activeFrom" timestamp(3) without time zone,
    "activeTo" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: fan_club_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fan_club_members (
    id text NOT NULL,
    "fanClubId" text NOT NULL,
    "userId" text NOT NULL,
    role text DEFAULT 'member'::text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    level text DEFAULT 'yeni_fan'::text NOT NULL,
    xp integer DEFAULT 0 NOT NULL
);


--
-- Name: fan_club_poll_votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fan_club_poll_votes (
    id text NOT NULL,
    "pollId" text NOT NULL,
    "userId" text NOT NULL,
    "optionIndex" integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: fan_club_polls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fan_club_polls (
    id text NOT NULL,
    "fanClubId" text NOT NULL,
    "userId" text NOT NULL,
    question text NOT NULL,
    options jsonb NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "endsAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: fan_club_post_likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fan_club_post_likes (
    id text NOT NULL,
    "postId" text NOT NULL,
    "userId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: fan_club_posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fan_club_posts (
    id text NOT NULL,
    "fanClubId" text NOT NULL,
    "userId" text NOT NULL,
    content text NOT NULL,
    image text,
    "likeCount" integer DEFAULT 0 NOT NULL,
    "isPinned" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: fan_clubs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fan_clubs (
    id text NOT NULL,
    "celebrityId" text NOT NULL,
    description text,
    rules text,
    "coverImage" text,
    "memberCount" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: favorite_tellers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.favorite_tellers (
    id text NOT NULL,
    "userId" text NOT NULL,
    "tellerId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: feature_flags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feature_flags (
    id text NOT NULL,
    key text NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    description text,
    platform text DEFAULT 'all'::text NOT NULL,
    percentage integer DEFAULT 100 NOT NULL,
    metadata jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: follows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.follows (
    id text NOT NULL,
    "followerId" text NOT NULL,
    "followingId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: fortune_ratings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fortune_ratings (
    id text NOT NULL,
    "fortuneId" text NOT NULL,
    "userId" text NOT NULL,
    satisfaction integer,
    accuracy integer,
    feedback text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: fortune_request_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fortune_request_types (
    id text NOT NULL,
    name text NOT NULL,
    "nameEn" text NOT NULL,
    icon text DEFAULT '☕'::text NOT NULL,
    "jetonCost" integer NOT NULL,
    description text,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: fortunes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fortunes (
    id text NOT NULL,
    "userId" text NOT NULL,
    "fortuneType" text NOT NULL,
    "inputData" text NOT NULL,
    "aiResponse" text NOT NULL,
    language text NOT NULL,
    "viewCount" integer DEFAULT 0 NOT NULL,
    "isSaved" boolean DEFAULT false NOT NULL,
    "isPinned" boolean DEFAULT false NOT NULL,
    "pinnedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: game_plays; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_plays (
    id text NOT NULL,
    "userId" text NOT NULL,
    "gameId" text NOT NULL,
    reward integer DEFAULT 0 NOT NULL,
    score integer,
    result text,
    "playedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: game_room_chats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_room_chats (
    id text NOT NULL,
    "roomId" text NOT NULL,
    "userId" text NOT NULL,
    "userName" text NOT NULL,
    message text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: game_room_viewers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_room_viewers (
    id text NOT NULL,
    "roomId" text NOT NULL,
    "userId" text NOT NULL,
    "userName" text NOT NULL,
    "joinedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: game_rooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_rooms (
    id text NOT NULL,
    "gameType" text NOT NULL,
    "player1Id" text NOT NULL,
    "player2Id" text,
    "isAI" boolean DEFAULT false NOT NULL,
    "betAmount" integer DEFAULT 0 NOT NULL,
    "betCurrency" text DEFAULT 'FREE'::text NOT NULL,
    state text DEFAULT '{}'::text NOT NULL,
    "currentTurn" integer DEFAULT 1 NOT NULL,
    "player1Score" integer DEFAULT 0 NOT NULL,
    "player2Score" integer DEFAULT 0 NOT NULL,
    status text DEFAULT 'waiting'::text NOT NULL,
    "winnerId" text,
    "player1Name" text DEFAULT 'Oyuncu 1'::text NOT NULL,
    "player2Name" text DEFAULT 'Oyuncu 2'::text NOT NULL,
    "turnTimer" integer DEFAULT 0 NOT NULL,
    "chatEnabled" boolean DEFAULT true NOT NULL,
    "lastMoveAt" timestamp(3) without time zone,
    "disconnectedPlayerId" text,
    "player1LastSeen" timestamp(3) without time zone,
    "player2LastSeen" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: gift_battle_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gift_battle_participants (
    id text NOT NULL,
    "battleId" text NOT NULL,
    "participantId" text NOT NULL,
    "displayName" text,
    score integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: gift_battles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gift_battles (
    id text NOT NULL,
    context text NOT NULL,
    "contextId" text NOT NULL,
    "createdById" text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    "durationSec" integer DEFAULT 180 NOT NULL,
    "startedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "endsAt" timestamp(3) without time zone NOT NULL,
    "winnerId" text,
    "totalScore" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: gift_box_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gift_box_entries (
    id text NOT NULL,
    "boxId" text NOT NULL,
    "userId" text NOT NULL,
    "taskVerified" boolean DEFAULT false NOT NULL,
    "isWinner" boolean DEFAULT false NOT NULL,
    "rewardAmount" integer DEFAULT 0 NOT NULL,
    rank integer,
    "joinedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: gift_boxes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gift_boxes (
    id text NOT NULL,
    scope text DEFAULT 'stream'::text NOT NULL,
    "streamId" text,
    "roomId" text,
    "creatorId" text NOT NULL,
    "totalAmount" integer NOT NULL,
    "winnerCount" integer NOT NULL,
    "durationSec" integer NOT NULL,
    splits text NOT NULL,
    "taskType" text DEFAULT 'none'::text NOT NULL,
    "taskTargetUserId" text,
    status text DEFAULT 'active'::text NOT NULL,
    "startsAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "endsAt" timestamp(3) without time zone NOT NULL,
    "finishedAt" timestamp(3) without time zone,
    "settledAt" timestamp(3) without time zone,
    "refundedAmount" integer DEFAULT 0 NOT NULL,
    "paidCount" integer DEFAULT 0 NOT NULL,
    "paidAmount" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: gift_collections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gift_collections (
    id text NOT NULL,
    name text NOT NULL,
    "nameEn" text DEFAULT ''::text NOT NULL,
    slug text NOT NULL,
    description text,
    "iconEmoji" text,
    "iconUrl" text,
    "iconCloudPath" text,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: gift_combos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gift_combos (
    id text NOT NULL,
    context text NOT NULL,
    "contextId" text NOT NULL,
    "senderId" text NOT NULL,
    "giftTypeId" text NOT NULL,
    "receiverId" text,
    "comboCount" integer DEFAULT 1 NOT NULL,
    "lastSentAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: gift_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gift_events (
    id text NOT NULL,
    "idempotencyKey" text,
    "giftTypeId" text NOT NULL,
    "senderId" text NOT NULL,
    "receiverId" text NOT NULL,
    context text NOT NULL,
    "contextId" text,
    quantity integer DEFAULT 1 NOT NULL,
    "grossAmount" integer NOT NULL,
    "siteAmount" integer DEFAULT 0 NOT NULL,
    "receiverAmount" integer DEFAULT 0 NOT NULL,
    "ownerAmount" integer DEFAULT 0 NOT NULL,
    "ownerId" text,
    "recipientIsOwner" boolean DEFAULT false NOT NULL,
    "senderCity" text,
    "senderCountry" text,
    "battleId" text,
    status text DEFAULT 'completed'::text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: gift_goals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gift_goals (
    id text NOT NULL,
    context text NOT NULL,
    "contextId" text NOT NULL,
    "ownerId" text NOT NULL,
    title text,
    "targetAmount" integer NOT NULL,
    "currentAmount" integer DEFAULT 0 NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    "startedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "completedAt" timestamp(3) without time zone
);


--
-- Name: gift_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gift_history (
    id text NOT NULL,
    context text NOT NULL,
    "contextId" text NOT NULL,
    "senderId" text NOT NULL,
    "receiverId" text NOT NULL,
    "giftTypeId" text NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    combo integer DEFAULT 1 NOT NULL,
    priority text DEFAULT 'MEDIUM'::text NOT NULL,
    "coinAmount" integer DEFAULT 0 NOT NULL,
    "animationType" text,
    "displayArea" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: gift_missions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gift_missions (
    id text NOT NULL,
    code text NOT NULL,
    title text NOT NULL,
    description text,
    type text NOT NULL,
    target integer DEFAULT 1 NOT NULL,
    context text,
    "rewardJetons" integer DEFAULT 0 NOT NULL,
    "rewardCredits" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: gift_queue; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gift_queue (
    id text NOT NULL,
    context text NOT NULL,
    "contextId" text NOT NULL,
    "giftTypeId" text NOT NULL,
    "senderId" text NOT NULL,
    "receiverId" text NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    combo integer DEFAULT 1 NOT NULL,
    priority text DEFAULT 'MEDIUM'::text NOT NULL,
    "durationMs" integer DEFAULT 3000 NOT NULL,
    "displayArea" text DEFAULT 'CENTER'::text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    "queueIndex" integer DEFAULT 0 NOT NULL,
    payload text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "playedAt" timestamp(3) without time zone,
    "finishedAt" timestamp(3) without time zone
);


--
-- Name: gift_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gift_types (
    id text NOT NULL,
    name text NOT NULL,
    "nameEn" text NOT NULL,
    icon text NOT NULL,
    animation text,
    price integer NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "assetType" text DEFAULT 'image'::text,
    "assetUrl" text,
    category text,
    "cloudStoragePath" text,
    description text,
    "thumbnailCloudPath" text,
    "thumbnailUrl" text,
    "updatedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "animationDurationMs" integer,
    "firstReleasedAt" timestamp(3) without time zone,
    "isFeatured" boolean DEFAULT false NOT NULL,
    "isFullscreen" boolean DEFAULT false NOT NULL,
    "isHidden" boolean DEFAULT false NOT NULL,
    "isNew" boolean DEFAULT false NOT NULL,
    "isPopular" boolean DEFAULT false NOT NULL,
    "isSpecialEvent" boolean DEFAULT false NOT NULL,
    "seasonEnd" timestamp(3) without time zone,
    "seasonStart" timestamp(3) without time zone,
    "soundCloudPath" text,
    "soundUrl" text,
    tier text DEFAULT 'small'::text NOT NULL,
    "comboEnabled" boolean DEFAULT false NOT NULL,
    "effectColor" text,
    "iconImageCloudPath" text,
    "iconImageUrl" text,
    "isPremium" boolean DEFAULT false NOT NULL,
    "animEndPoint" text,
    "animStartPoint" text,
    "campaignEnd" timestamp(3) without time zone,
    "campaignStart" timestamp(3) without time zone,
    "collectionId" text,
    "contentVersion" integer DEFAULT 1 NOT NULL,
    "dailySendLimit" integer,
    "displayDurationMs" integer,
    "displayType" text DEFAULT 'static'::text NOT NULL,
    "eventOnly" boolean DEFAULT false NOT NULL,
    "hasColorChange" boolean DEFAULT false NOT NULL,
    "hasVibration" boolean DEFAULT false NOT NULL,
    "isReusable" boolean DEFAULT true NOT NULL,
    "isSeasonal" boolean DEFAULT false NOT NULL,
    "liveOnly" boolean DEFAULT false NOT NULL,
    "musicCloudPath" text,
    "musicUrl" text,
    "newUserOnly" boolean DEFAULT false NOT NULL,
    "particleEffect" text,
    "pkOnly" boolean DEFAULT false NOT NULL,
    "repeatCount" integer DEFAULT 1 NOT NULL,
    "requiresVip" boolean DEFAULT false NOT NULL,
    "screenPosition" text DEFAULT 'center'::text NOT NULL,
    "startDelayMs" integer,
    "timedCampaign" boolean DEFAULT false NOT NULL,
    "visibleAsFullscreen" boolean DEFAULT false NOT NULL,
    "visibleAsMini" boolean DEFAULT false NOT NULL,
    "visibleInFortune" boolean DEFAULT false NOT NULL,
    "visibleInLiveStream" boolean DEFAULT true NOT NULL,
    "visibleInMessaging" boolean DEFAULT false NOT NULL,
    "visibleInNotification" boolean DEFAULT false NOT NULL,
    "visibleInPK" boolean DEFAULT true NOT NULL,
    "visibleInProfile" boolean DEFAULT false NOT NULL,
    "visibleInStories" boolean DEFAULT false NOT NULL,
    "visibleInTrend" boolean DEFAULT false NOT NULL,
    "visibleInVoiceRoom" boolean DEFAULT true NOT NULL,
    "voiceOnly" boolean DEFAULT false NOT NULL,
    volume integer DEFAULT 100 NOT NULL,
    "isLucky" boolean DEFAULT false NOT NULL,
    "animationType" text,
    "comboWindowMs" integer DEFAULT 4000 NOT NULL,
    "displayArea" text,
    priority text DEFAULT 'MEDIUM'::text NOT NULL,
    "seatEffect" text,
    "seatEffectEnabled" boolean DEFAULT true NOT NULL,
    "soundEffectEnabled" boolean DEFAULT true NOT NULL,
    "assetDurationMs" integer,
    "assetHeight" integer,
    "assetMimeType" text,
    "assetWidth" integer
);


--
-- Name: hashtags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hashtags (
    id text NOT NULL,
    name text NOT NULL,
    "videosCount" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: homepage_buttons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.homepage_buttons (
    id text NOT NULL,
    key text NOT NULL,
    label text NOT NULL,
    icon text DEFAULT '🔗'::text NOT NULL,
    href text NOT NULL,
    "isVisible" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "specialBehavior" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: homepage_fortune_cards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.homepage_fortune_cards (
    id text NOT NULL,
    name text NOT NULL,
    icon text DEFAULT '🔮'::text NOT NULL,
    image text DEFAULT ''::text NOT NULL,
    href text DEFAULT '/fallar'::text NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: idempotency_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.idempotency_records (
    id text NOT NULL,
    key text NOT NULL,
    scope text NOT NULL,
    "userId" text,
    status text DEFAULT 'in_flight'::text NOT NULL,
    "responseStatus" integer,
    "responseBody" jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "expiresAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: integration_secrets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integration_secrets (
    id text NOT NULL,
    scope text NOT NULL,
    "providerKey" text NOT NULL,
    "fieldKey" text NOT NULL,
    ciphertext text NOT NULL,
    iv text NOT NULL,
    "authTag" text NOT NULL,
    "keyVersion" integer DEFAULT 1 NOT NULL,
    "updatedBy" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: integration_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integration_settings (
    id text NOT NULL,
    key text NOT NULL,
    value text NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: invite_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invite_codes (
    id text NOT NULL,
    "agencyId" text NOT NULL,
    code text NOT NULL,
    "createdById" text NOT NULL,
    "maxUses" integer DEFAULT 0 NOT NULL,
    "usedCount" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "expiresAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: ip_fortune_usage; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ip_fortune_usage (
    id text NOT NULL,
    "ipAddress" text NOT NULL,
    date date NOT NULL,
    count integer DEFAULT 1 NOT NULL,
    "adWatched" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: jeton_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.jeton_transactions (
    id text NOT NULL,
    "userId" text NOT NULL,
    amount integer NOT NULL,
    type text NOT NULL,
    description text,
    "itemSlug" text,
    "balanceBefore" integer NOT NULL,
    "balanceAfter" integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: leaderboard_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leaderboard_configs (
    id text NOT NULL,
    scope text NOT NULL,
    "periodType" text NOT NULL,
    "isEnabled" boolean DEFAULT true NOT NULL,
    "topN" integer DEFAULT 100 NOT NULL,
    "rewardConfig" jsonb,
    "scoringRules" jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: leaderboard_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leaderboard_entries (
    id text NOT NULL,
    "periodId" text NOT NULL,
    "userId" text NOT NULL,
    "contextId" text,
    score integer DEFAULT 0 NOT NULL,
    rank integer,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: leaderboard_periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leaderboard_periods (
    id text NOT NULL,
    "configId" text NOT NULL,
    scope text NOT NULL,
    "periodType" text NOT NULL,
    "periodKey" text NOT NULL,
    "startTime" timestamp(3) without time zone NOT NULL,
    "endTime" timestamp(3) without time zone NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    "finalizedAt" timestamp(3) without time zone,
    "rewardedAt" timestamp(3) without time zone
);


--
-- Name: leaderboard_rewards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leaderboard_rewards (
    id text NOT NULL,
    "periodId" text NOT NULL,
    "userId" text NOT NULL,
    rank integer NOT NULL,
    "rewardType" text NOT NULL,
    "rewardValue" text NOT NULL,
    "rewardLabel" text,
    status text DEFAULT 'pending'::text NOT NULL,
    "distributedAt" timestamp(3) without time zone,
    "transactionId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: ledger_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ledger_entries (
    id text NOT NULL,
    "transactionId" text NOT NULL,
    "accountType" text NOT NULL,
    "accountId" text NOT NULL,
    direction text NOT NULL,
    amount integer NOT NULL,
    currency text DEFAULT 'jeton'::text NOT NULL,
    "balanceBefore" integer DEFAULT 0 NOT NULL,
    "balanceAfter" integer DEFAULT 0 NOT NULL,
    category text NOT NULL,
    description text,
    "referenceType" text,
    "referenceId" text,
    metadata jsonb,
    "actorId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: live_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.live_activities (
    id text NOT NULL,
    "userId" text,
    "userName" text NOT NULL,
    "userAvatar" text,
    "activityType" text NOT NULL,
    detail text,
    "targetUrl" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: live_fortune_tellers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.live_fortune_tellers (
    id text NOT NULL,
    "userId" text NOT NULL,
    "displayName" text NOT NULL,
    bio text,
    specialties text[],
    "pricePerSession" integer DEFAULT 100 NOT NULL,
    rating double precision DEFAULT 5.0 NOT NULL,
    "totalSessions" integer DEFAULT 0 NOT NULL,
    "totalReviews" integer DEFAULT 0 NOT NULL,
    "isOnline" boolean DEFAULT false NOT NULL,
    "isVerified" boolean DEFAULT false NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    avatar text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "applicationNote" text,
    "applicationStatus" text DEFAULT 'pending'::text NOT NULL,
    "approvedAt" timestamp(3) without time zone,
    "banReason" text,
    "bannedAt" timestamp(3) without time zone,
    "bonusCredits" integer DEFAULT 0 NOT NULL,
    "freezeReason" text,
    "frozenAt" timestamp(3) without time zone,
    "isBanned" boolean DEFAULT false NOT NULL,
    "isFrozen" boolean DEFAULT false NOT NULL,
    "rejectedAt" timestamp(3) without time zone,
    "totalEarnings" integer DEFAULT 0 NOT NULL,
    "canGoOnline" boolean DEFAULT true NOT NULL,
    "canChat" boolean DEFAULT true NOT NULL,
    "canStartSession" boolean DEFAULT true NOT NULL,
    "canSetPrice" boolean DEFAULT false NOT NULL,
    "canEditProfile" boolean DEFAULT true NOT NULL,
    "canViewEarnings" boolean DEFAULT true NOT NULL,
    "canWithdraw" boolean DEFAULT false NOT NULL,
    "maxSessionsPerDay" integer DEFAULT 10 NOT NULL,
    "commissionRate" integer DEFAULT 20 NOT NULL,
    "adminNotes" text,
    "levelPoints" integer DEFAULT 0 NOT NULL,
    "levelUpdatedAt" timestamp(3) without time zone,
    "tellerLevel" text DEFAULT 'bronze'::text NOT NULL,
    "verificationDocUrl" text,
    "verificationNote" text,
    "verificationStatus" text DEFAULT 'none'::text NOT NULL
);


--
-- Name: live_guest_invites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.live_guest_invites (
    id text NOT NULL,
    "streamId" text NOT NULL,
    "hostId" text NOT NULL,
    "guestId" text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "respondedAt" timestamp(3) without time zone,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    "cancelledAt" timestamp(3) without time zone,
    kind text DEFAULT 'invite'::text NOT NULL,
    message text,
    "respondedBy" text
);


--
-- Name: live_guest_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.live_guest_sessions (
    id text NOT NULL,
    "streamId" text NOT NULL,
    "userId" text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    slot integer NOT NULL,
    "isMuted" boolean DEFAULT false NOT NULL,
    "isVideoOff" boolean DEFAULT false NOT NULL,
    "mutedByHost" boolean DEFAULT false NOT NULL,
    "joinedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "lastSeenAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "leftAt" timestamp(3) without time zone,
    "approvedBy" text,
    source text DEFAULT 'invite'::text NOT NULL,
    "videoOffByHost" boolean DEFAULT false NOT NULL
);


--
-- Name: live_session_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.live_session_messages (
    id text NOT NULL,
    "sessionId" text NOT NULL,
    "senderId" text NOT NULL,
    message text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: live_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.live_sessions (
    id text NOT NULL,
    "tellerId" text NOT NULL,
    "userId" text NOT NULL,
    "fortuneType" text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    "creditsCharged" integer NOT NULL,
    "startedAt" timestamp(3) without time zone,
    "endedAt" timestamp(3) without time zone,
    notes text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "roomId" text,
    "maxMinutes" integer DEFAULT 5 NOT NULL,
    "minutesUsed" integer DEFAULT 0 NOT NULL,
    "creditsPerMinute" integer DEFAULT 0 NOT NULL,
    "lastPingAt" timestamp(3) without time zone,
    "timerStarted" boolean DEFAULT false NOT NULL,
    "timerStartedAt" timestamp(3) without time zone
);


--
-- Name: live_teller_reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.live_teller_reviews (
    id text NOT NULL,
    "tellerId" text NOT NULL,
    "sessionId" text NOT NULL,
    rating integer NOT NULL,
    comment text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: lucky_gift_rewards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lucky_gift_rewards (
    id text NOT NULL,
    "userId" text NOT NULL,
    "giftTypeId" text NOT NULL,
    context text,
    "contextId" text,
    "betJetons" integer NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    multiplier integer NOT NULL,
    "wonJetons" integer NOT NULL,
    "netJetons" integer NOT NULL,
    "isJackpot" boolean DEFAULT false NOT NULL,
    "tierId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: lucky_gift_tiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lucky_gift_tiers (
    id text NOT NULL,
    name text NOT NULL,
    "nameEn" text DEFAULT ''::text NOT NULL,
    multiplier integer NOT NULL,
    weight integer DEFAULT 1 NOT NULL,
    "isJackpot" boolean DEFAULT false NOT NULL,
    color text,
    icon text,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "contentVersion" integer DEFAULT 1 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: membership_badges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.membership_badges (
    id text NOT NULL,
    name text NOT NULL,
    tier text NOT NULL,
    "imageUrl" text NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: membership_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.membership_events (
    id text NOT NULL,
    title text NOT NULL,
    description text,
    "bannerUrl" text,
    "ctaUrl" text,
    "startsAt" timestamp(3) without time zone NOT NULL,
    "endsAt" timestamp(3) without time zone NOT NULL,
    "minTierKey" text,
    "allowedTiers" text[] DEFAULT ARRAY[]::text[],
    "isActive" boolean DEFAULT true NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    "createdBy" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: membership_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.membership_features (
    id text NOT NULL,
    key text NOT NULL,
    name text NOT NULL,
    "nameEn" text DEFAULT ''::text NOT NULL,
    category text DEFAULT 'general'::text NOT NULL,
    description text,
    "valueType" text DEFAULT 'boolean'::text NOT NULL,
    unit text,
    options jsonb,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: membership_grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.membership_grants (
    id text NOT NULL,
    "receiverId" text NOT NULL,
    "giverId" text,
    "tierKey" text NOT NULL,
    "previousTier" text,
    source text DEFAULT 'purchase'::text NOT NULL,
    "startsAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "expiresAt" timestamp(3) without time zone,
    "transactionId" text,
    status text DEFAULT 'active'::text NOT NULL,
    "autoRenew" boolean DEFAULT false NOT NULL,
    note text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: membership_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.membership_plans (
    id text NOT NULL,
    name text NOT NULL,
    "nameEn" text,
    description text,
    "descriptionEn" text,
    tier text NOT NULL,
    "durationDays" integer NOT NULL,
    "priceType" text NOT NULL,
    price integer NOT NULL,
    currency text DEFAULT 'TRY'::text NOT NULL,
    features text,
    "bonusJetons" integer DEFAULT 0 NOT NULL,
    "discountPercent" integer DEFAULT 0 NOT NULL,
    "prioritySupport" boolean DEFAULT false NOT NULL,
    "exclusiveBadge" text,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "isFeatured" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: membership_purchases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.membership_purchases (
    id text NOT NULL,
    "userId" text NOT NULL,
    "planId" text,
    "priceType" text NOT NULL,
    "pricePaid" integer NOT NULL,
    currency text DEFAULT 'TRY'::text NOT NULL,
    "startsAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "grantedBy" text
);


--
-- Name: membership_tier_defs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.membership_tier_defs (
    id text NOT NULL,
    key text NOT NULL,
    name text NOT NULL,
    "nameEn" text DEFAULT ''::text NOT NULL,
    rank integer DEFAULT 0 NOT NULL,
    color text DEFAULT '#9ca3af'::text NOT NULL,
    gradient text,
    icon text DEFAULT '⭐'::text NOT NULL,
    "badgeUrl" text,
    "frameUrl" text,
    description text,
    "discoveryWeight" double precision DEFAULT 1.0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: membership_tier_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.membership_tier_features (
    id text NOT NULL,
    "tierKey" text NOT NULL,
    "featureKey" text NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    "limitValue" integer,
    "dailyLimit" integer,
    "monthlyLimit" integer,
    "durationDays" integer,
    priority integer DEFAULT 0 NOT NULL,
    "assetRef" text,
    "defaultValue" jsonb,
    metadata jsonb,
    "updatedBy" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: message_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_requests (
    id text NOT NULL,
    "senderId" text NOT NULL,
    "receiverId" text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    message text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: mic_frames; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mic_frames (
    id text NOT NULL,
    name text NOT NULL,
    "assetUrl" text NOT NULL,
    tier text DEFAULT 'gold'::text NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: mini_games; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mini_games (
    id text NOT NULL,
    slug text NOT NULL,
    title text NOT NULL,
    description text,
    icon text DEFAULT '🎮'::text NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "entryFee" integer DEFAULT 0 NOT NULL,
    "minReward" integer DEFAULT 5 NOT NULL,
    "maxReward" integer DEFAULT 50 NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    config text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: name_effects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_effects (
    id text NOT NULL,
    key text NOT NULL,
    name text NOT NULL,
    tier text DEFAULT 'gold'::text NOT NULL,
    "cssPreset" text,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id text NOT NULL,
    "userId" text NOT NULL,
    type text NOT NULL,
    title text,
    message text NOT NULL,
    data text,
    "postId" text,
    "fromUserId" text,
    "fromUserName" text,
    "isRead" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "dedupeKey" text,
    "deepLink" text
);


--
-- Name: okey_match_players; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.okey_match_players (
    id text NOT NULL,
    "matchId" text NOT NULL,
    "userId" text NOT NULL,
    "userName" text NOT NULL,
    seat integer NOT NULL,
    "isWinner" boolean DEFAULT false NOT NULL,
    score integer DEFAULT 0 NOT NULL,
    "penaltyScore" integer DEFAULT 0 NOT NULL,
    "betPaid" integer DEFAULT 0 NOT NULL,
    "rewardWon" integer DEFAULT 0 NOT NULL,
    "leftEarly" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: okey_matches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.okey_matches (
    id text NOT NULL,
    mode text NOT NULL,
    "tableName" text,
    "isPrivate" boolean DEFAULT false NOT NULL,
    "hasPassword" boolean DEFAULT false NOT NULL,
    "betAmount" integer DEFAULT 0 NOT NULL,
    "betCurrency" text DEFAULT 'FREE'::text NOT NULL,
    "commissionPct" integer DEFAULT 0 NOT NULL,
    "potAmount" integer DEFAULT 0 NOT NULL,
    status text DEFAULT 'finished'::text NOT NULL,
    "winnerId" text,
    "winnerName" text,
    reason text,
    "durationSec" integer DEFAULT 0 NOT NULL,
    "roundCount" integer DEFAULT 1 NOT NULL,
    "indicatorTile" text,
    "okeyTile" text,
    "startedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "finishedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: online_fal_buttons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.online_fal_buttons (
    id text NOT NULL,
    label text NOT NULL,
    icon text DEFAULT '🔗'::text NOT NULL,
    href text NOT NULL,
    "isVisible" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "bgColor" text DEFAULT 'from-purple-600/30 to-fuchsia-600/30'::text NOT NULL,
    "borderColor" text DEFAULT 'border-purple-400/50'::text NOT NULL,
    "textColor" text DEFAULT 'text-purple-200'::text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: online_fal_sections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.online_fal_sections (
    id text NOT NULL,
    key text NOT NULL,
    title text NOT NULL,
    icon text DEFAULT '✨'::text NOT NULL,
    "isVisible" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.password_reset_tokens (
    id text NOT NULL,
    "userId" text NOT NULL,
    token text NOT NULL,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    used boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: payment_methods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_methods (
    id text NOT NULL,
    type text NOT NULL,
    name text NOT NULL,
    "nameEn" text,
    description text,
    "descriptionEn" text,
    "isActive" boolean DEFAULT true NOT NULL,
    config text,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: payment_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_notifications (
    id text NOT NULL,
    "userId" text NOT NULL,
    username text NOT NULL,
    "paymentMethod" text NOT NULL,
    amount double precision NOT NULL,
    "transactionId" text,
    "senderName" text,
    notes text,
    status text DEFAULT 'pending'::text NOT NULL,
    "jetonLoaded" integer,
    "processedBy" text,
    "processedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "adminNote" text,
    "cfcLoaded" integer,
    "correctedAmount" integer,
    "correctedAt" timestamp(3) without time zone,
    "correctedBy" text,
    "correctionReason" text,
    "creditApplied" boolean DEFAULT false NOT NULL,
    "creditAppliedAt" timestamp(3) without time zone,
    "goldDaysLoaded" integer,
    "goldTypeLoaded" text,
    "originalRequestedAmount" integer,
    "processedByName" text,
    "productType" text DEFAULT 'jeton'::text NOT NULL,
    "proofUrl" text,
    "requestedAmount" integer,
    "requestedGoldDays" integer,
    "requestedGoldType" text
);


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    id text NOT NULL,
    "userId" text NOT NULL,
    "packageId" text,
    "stripeSessionId" text,
    "stripePaymentIntentId" text,
    amount double precision NOT NULL,
    currency text DEFAULT 'TRY'::text NOT NULL,
    "creditsAwarded" integer NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    "paymentMethod" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "completedAt" timestamp(3) without time zone
);


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permissions (
    id text NOT NULL,
    key text NOT NULL,
    name text NOT NULL,
    description text,
    "group" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: phone_otps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.phone_otps (
    id text NOT NULL,
    "userId" text NOT NULL,
    phone text NOT NULL,
    code text,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    used boolean DEFAULT false NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "codeHash" text,
    "deviceId" text,
    "idempotencyKey" text,
    ip text,
    "providerKey" text
);


--
-- Name: pk_bans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pk_bans (
    id text NOT NULL,
    "userId" text NOT NULL,
    reason text,
    "bannedBy" text NOT NULL,
    active boolean DEFAULT true NOT NULL,
    "expiresAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: pk_battle_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pk_battle_participants (
    id text NOT NULL,
    "battleId" text NOT NULL,
    side integer NOT NULL,
    "userId" text NOT NULL,
    "seatNumber" integer,
    points integer DEFAULT 0 NOT NULL,
    "isCaptain" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: pk_battles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pk_battles (
    id text NOT NULL,
    "stream1Id" text NOT NULL,
    "stream2Id" text NOT NULL,
    "user1Id" text NOT NULL,
    "user2Id" text NOT NULL,
    score1 integer DEFAULT 0 NOT NULL,
    score2 integer DEFAULT 0 NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    duration integer DEFAULT 300 NOT NULL,
    "startedAt" timestamp(3) without time zone,
    "endedAt" timestamp(3) without time zone,
    "winnerId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "acceptedAt" timestamp(3) without time zone,
    "endsAt" timestamp(3) without time zone,
    "isDraw" boolean DEFAULT false NOT NULL,
    "winnerSide" integer,
    mode text DEFAULT '1v1'::text NOT NULL,
    "pausedAt" timestamp(3) without time zone,
    "pausedMs" integer DEFAULT 0 NOT NULL,
    scope text DEFAULT 'stream'::text NOT NULL,
    "scopeRoomId" text
);


--
-- Name: pk_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pk_events (
    id text NOT NULL,
    "matchId" text NOT NULL,
    type text NOT NULL,
    multiplier double precision DEFAULT 2.0 NOT NULL,
    "startsAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "endsAt" timestamp(3) without time zone NOT NULL,
    "createdBy" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: pk_gifts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pk_gifts (
    id text NOT NULL,
    "battleId" text NOT NULL,
    side integer NOT NULL,
    "senderId" text NOT NULL,
    "receiverId" text NOT NULL,
    "giftTypeId" text NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    points integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: pk_matches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pk_matches (
    id text NOT NULL,
    "hostUserId" text NOT NULL,
    "hostStreamId" text NOT NULL,
    "hostName" text,
    "hostImage" text,
    "guestUserId" text NOT NULL,
    "guestStreamId" text,
    "guestName" text,
    "guestImage" text,
    status text DEFAULT 'pending'::text NOT NULL,
    "durationSec" integer DEFAULT 180 NOT NULL,
    "hostScore" integer DEFAULT 0 NOT NULL,
    "guestScore" integer DEFAULT 0 NOT NULL,
    result text,
    "winnerUserId" text,
    "finalSprint" boolean DEFAULT false NOT NULL,
    "requestedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "respondedAt" timestamp(3) without time zone,
    "startedAt" timestamp(3) without time zone,
    "endsAt" timestamp(3) without time zone,
    "finishedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "leftName" text,
    "leftScore" integer DEFAULT 0 NOT NULL,
    mode text DEFAULT '1v1'::text NOT NULL,
    "rightName" text,
    "rightScore" integer DEFAULT 0 NOT NULL,
    "seatCount" integer DEFAULT 2 NOT NULL
);


--
-- Name: pk_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pk_participants (
    id text NOT NULL,
    "matchId" text NOT NULL,
    "userId" text NOT NULL,
    mode text NOT NULL,
    side text NOT NULL,
    score integer DEFAULT 0 NOT NULL,
    outcome text NOT NULL,
    "finishedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: pk_scores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pk_scores (
    id text NOT NULL,
    "battleId" text NOT NULL,
    side integer NOT NULL,
    "contributorId" text NOT NULL,
    points integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    source text DEFAULT 'gift'::text NOT NULL
);


--
-- Name: pk_seats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pk_seats (
    id text NOT NULL,
    "matchId" text NOT NULL,
    "seatIndex" integer NOT NULL,
    team text DEFAULT 'none'::text NOT NULL,
    "userId" text NOT NULL,
    "userName" text,
    "userImage" text,
    "streamId" text,
    score integer DEFAULT 0 NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    "joinedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "leftAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: pk_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pk_stats (
    "userId" text NOT NULL,
    matches integer DEFAULT 0 NOT NULL,
    wins integer DEFAULT 0 NOT NULL,
    losses integer DEFAULT 0 NOT NULL,
    draws integer DEFAULT 0 NOT NULL,
    "totalScore" integer DEFAULT 0 NOT NULL,
    "bestScore" integer DEFAULT 0 NOT NULL,
    "currentStreak" integer DEFAULT 0 NOT NULL,
    "bestStreak" integer DEFAULT 0 NOT NULL,
    "lastPlayedAt" timestamp(3) without time zone,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: platform_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platform_settings (
    id text NOT NULL,
    key text NOT NULL,
    value text NOT NULL,
    description text,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: profile_frames; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_frames (
    id text NOT NULL,
    name text NOT NULL,
    "imageUrl" text NOT NULL,
    tier text DEFAULT 'gold'::text NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: profile_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_views (
    id text NOT NULL,
    "viewedUserId" text NOT NULL,
    "viewerId" text,
    "viewedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: profile_visits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_visits (
    id text NOT NULL,
    "visitorId" text NOT NULL,
    "profileId" text NOT NULL,
    "isHidden" boolean DEFAULT false NOT NULL,
    "visitedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: push_notification_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.push_notification_logs (
    id text NOT NULL,
    "onesignalId" text,
    title text NOT NULL,
    message text NOT NULL,
    url text,
    "imageUrl" text,
    "targetType" text NOT NULL,
    "targetValue" text,
    "scheduledAt" timestamp(3) without time zone,
    status text DEFAULT 'sent'::text NOT NULL,
    "recipientCount" integer DEFAULT 0 NOT NULL,
    "deliveredCount" integer DEFAULT 0 NOT NULL,
    "clickedCount" integer DEFAULT 0 NOT NULL,
    "errorMessage" text,
    "createdBy" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: referral_commissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.referral_commissions (
    id text NOT NULL,
    "earnerId" text NOT NULL,
    "sourceUserId" text NOT NULL,
    "agencyId" text,
    "commissionType" text DEFAULT 'referral'::text NOT NULL,
    "topupAmount" integer NOT NULL,
    "topupCurrency" text DEFAULT 'credits'::text NOT NULL,
    rate double precision NOT NULL,
    amount integer NOT NULL,
    currency text DEFAULT 'credits'::text NOT NULL,
    "sourceType" text DEFAULT 'admin_credit'::text NOT NULL,
    "sourceId" text,
    note text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: referrals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.referrals (
    id text NOT NULL,
    "referrerId" text NOT NULL,
    "referredId" text NOT NULL,
    "creditsAwarded" integer DEFAULT 50 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: refund_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.refund_requests (
    id text NOT NULL,
    "userId" text NOT NULL,
    "paymentId" text,
    "storePurchaseId" text,
    amount double precision NOT NULL,
    currency text DEFAULT 'TRY'::text NOT NULL,
    reason text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    "adminNote" text,
    "resolvedBy" text,
    "resolvedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: remote_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.remote_configs (
    id text NOT NULL,
    key text NOT NULL,
    value jsonb NOT NULL,
    "valueType" text DEFAULT 'json'::text NOT NULL,
    "group" text DEFAULT 'general'::text NOT NULL,
    description text,
    platform text DEFAULT 'all'::text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: revenue_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.revenue_rules (
    id text NOT NULL,
    context text NOT NULL,
    label text NOT NULL,
    "sitePercent" integer DEFAULT 50 NOT NULL,
    "receiverPercent" integer DEFAULT 50 NOT NULL,
    "ownerCutOfRemainderPercent" integer DEFAULT 30 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "updatedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: revoked_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.revoked_tokens (
    id text NOT NULL,
    "tokenHash" text NOT NULL,
    "userId" text NOT NULL,
    "tokenType" text DEFAULT 'access'::text NOT NULL,
    reason text,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: risk_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.risk_events (
    id text NOT NULL,
    "userId" text NOT NULL,
    category text NOT NULL,
    score integer DEFAULT 0 NOT NULL,
    level text NOT NULL,
    signals jsonb,
    amount double precision,
    currency text,
    "referenceType" text,
    "referenceId" text,
    ip text,
    reviewed boolean DEFAULT false NOT NULL,
    "reviewedBy" text,
    "reviewedAt" timestamp(3) without time zone,
    "reviewNote" text,
    metadata jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_permissions (
    id text NOT NULL,
    "roleId" text NOT NULL,
    "permissionId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id text NOT NULL,
    key text NOT NULL,
    name text NOT NULL,
    description text,
    level integer DEFAULT 0 NOT NULL,
    "isSystem" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: room_revenue_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.room_revenue_logs (
    id text NOT NULL,
    "roomId" text NOT NULL,
    "eventType" text NOT NULL,
    "totalAmount" integer NOT NULL,
    "receiverAmount" integer DEFAULT 0 NOT NULL,
    "ownerAmount" integer DEFAULT 0 NOT NULL,
    "siteAmount" integer DEFAULT 0 NOT NULL,
    "senderId" text,
    "receiverId" text,
    "ownerId" text,
    metadata text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: room_signals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.room_signals (
    id text NOT NULL,
    "sessionId" text NOT NULL,
    "senderId" text NOT NULL,
    "receiverId" text NOT NULL,
    "signalType" text NOT NULL,
    "signalData" text NOT NULL,
    processed boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: room_themes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.room_themes (
    id text NOT NULL,
    name text NOT NULL,
    "backgroundUrl" text NOT NULL,
    "assetType" text DEFAULT 'image'::text NOT NULL,
    tier text DEFAULT 'free'::text NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "activeFrom" timestamp(3) without time zone,
    "activeTo" timestamp(3) without time zone,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "animationSpeed" double precision DEFAULT 1.0,
    "blurAmount" integer DEFAULT 0,
    category text,
    "cloudStoragePath" text,
    "contentVersion" integer DEFAULT 1 NOT NULL,
    description text,
    "hasParallax" boolean DEFAULT false NOT NULL,
    "hasZoom" boolean DEFAULT false NOT NULL,
    "isEventOnly" boolean DEFAULT false NOT NULL,
    "isPremium" boolean DEFAULT false NOT NULL,
    "isVipOnly" boolean DEFAULT false NOT NULL,
    "nameEn" text DEFAULT ''::text NOT NULL,
    opacity double precision DEFAULT 1.0,
    "soundCloudPath" text,
    "soundUrl" text,
    "soundVolume" integer DEFAULT 50,
    "thumbnailCloudPath" text,
    "thumbnailUrl" text,
    "videoLoop" boolean DEFAULT true NOT NULL
);


--
-- Name: rtc_telemetry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rtc_telemetry (
    id text NOT NULL,
    "userId" text NOT NULL,
    context text NOT NULL,
    "contextId" text,
    "peerId" text,
    "connectionState" text,
    "iceState" text,
    "reconnectCount" integer DEFAULT 0 NOT NULL,
    "rttMs" double precision,
    "packetLossPercent" double precision,
    "jitterMs" double precision,
    "bitrateKbps" double precision,
    "freezeCount" integer DEFAULT 0 NOT NULL,
    "freezeDurationMs" integer DEFAULT 0 NOT NULL,
    "durationSeconds" integer DEFAULT 0 NOT NULL,
    "qualityScore" integer,
    "qualityLevel" text,
    platform text,
    "networkType" text,
    metadata jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id text NOT NULL,
    "sessionToken" text NOT NULL,
    "userId" text NOT NULL,
    expires timestamp(3) without time zone NOT NULL
);


--
-- Name: share_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.share_events (
    id text NOT NULL,
    "userId" text NOT NULL,
    scope text NOT NULL,
    "targetId" text NOT NULL,
    channel text DEFAULT 'link'::text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: short_video_comment_likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.short_video_comment_likes (
    id text NOT NULL,
    "commentId" text NOT NULL,
    "userId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: short_video_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.short_video_comments (
    id text NOT NULL,
    "videoId" text NOT NULL,
    "userId" text NOT NULL,
    content character varying(500) NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "isPinned" boolean DEFAULT false NOT NULL,
    "likesCount" integer DEFAULT 0 NOT NULL,
    "parentId" text
);


--
-- Name: short_video_hashtags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.short_video_hashtags (
    id text NOT NULL,
    "videoId" text NOT NULL,
    "hashtagId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: short_video_likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.short_video_likes (
    id text NOT NULL,
    "videoId" text NOT NULL,
    "userId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: short_video_mentions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.short_video_mentions (
    id text NOT NULL,
    "videoId" text NOT NULL,
    "mentionedUserId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: short_video_music; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.short_video_music (
    id text NOT NULL,
    title text NOT NULL,
    artist text,
    "audioUrl" text NOT NULL,
    "coverUrl" text,
    "durationSec" double precision,
    "usesCount" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: short_video_saves; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.short_video_saves (
    id text NOT NULL,
    "videoId" text NOT NULL,
    "userId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: short_video_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.short_video_views (
    id text NOT NULL,
    "videoId" text NOT NULL,
    "userId" text NOT NULL,
    "watchedSec" double precision,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: short_videos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.short_videos (
    id text NOT NULL,
    "userId" text NOT NULL,
    "videoUrl" text NOT NULL,
    "thumbnailUrl" text,
    description character varying(500),
    "durationSec" double precision,
    "viewsCount" integer DEFAULT 0 NOT NULL,
    "likesCount" integer DEFAULT 0 NOT NULL,
    "commentsCount" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "allowDuet" boolean DEFAULT true NOT NULL,
    "commentSetting" text DEFAULT 'everyone'::text NOT NULL,
    "duetOfId" text,
    "locationLat" double precision,
    "locationLng" double precision,
    "locationName" text,
    "musicId" text,
    "savesCount" integer DEFAULT 0 NOT NULL,
    "sharesCount" integer DEFAULT 0 NOT NULL,
    visibility text DEFAULT 'everyone'::text NOT NULL
);


--
-- Name: site_announcements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_announcements (
    id text NOT NULL,
    type text NOT NULL,
    message text NOT NULL,
    color text DEFAULT 'red'::text NOT NULL,
    "userId" text,
    "userName" text,
    "maxPasses" integer DEFAULT 1 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "expiresAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: site_pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_pages (
    id text NOT NULL,
    title text NOT NULL,
    "titleEn" text,
    slug text NOT NULL,
    content text NOT NULL,
    "contentEn" text,
    "isPublished" boolean DEFAULT true NOT NULL,
    "showInFooter" boolean DEFAULT true NOT NULL,
    "showInHeader" boolean DEFAULT false NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: site_presences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_presences (
    id text NOT NULL,
    "visitorId" text NOT NULL,
    "userId" text,
    "lastSeen" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "userAgent" text,
    path text,
    "deviceType" text,
    "isBot" boolean DEFAULT false NOT NULL,
    "botName" text
);


--
-- Name: site_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_settings (
    id text NOT NULL,
    key text NOT NULL,
    value text NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: site_visits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_visits (
    id text NOT NULL,
    "visitorId" text NOT NULL,
    "userId" text,
    "visitedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    path text,
    "userAgent" text,
    country text,
    city text,
    "ipHash" text,
    "deviceType" text,
    "isBot" boolean DEFAULT false NOT NULL,
    "botName" text
);


--
-- Name: sms_delivery_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sms_delivery_logs (
    id text NOT NULL,
    "providerKey" text NOT NULL,
    "phoneMasked" text NOT NULL,
    purpose text DEFAULT 'otp'::text NOT NULL,
    success boolean NOT NULL,
    "errorCode" text,
    "latencyMs" integer,
    "isFallback" boolean DEFAULT false NOT NULL,
    "isTest" boolean DEFAULT false NOT NULL,
    "idempotencyKey" text,
    "providerMessageId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sms_provider_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sms_provider_configs (
    id text NOT NULL,
    "providerKey" text NOT NULL,
    "fieldKey" text NOT NULL,
    value text NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: sms_provider_health; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sms_provider_health (
    id text NOT NULL,
    "providerKey" text NOT NULL,
    status text DEFAULT 'unknown'::text NOT NULL,
    "lastSuccessAt" timestamp(3) without time zone,
    "lastFailureAt" timestamp(3) without time zone,
    "lastTestedAt" timestamp(3) without time zone,
    "lastUsedAt" timestamp(3) without time zone,
    "lastError" text,
    "successCount" integer DEFAULT 0 NOT NULL,
    "failureCount" integer DEFAULT 0 NOT NULL,
    "fallbackUseCount" integer DEFAULT 0 NOT NULL,
    "avgLatencyMs" integer DEFAULT 0 NOT NULL,
    "cooldownUntil" timestamp(3) without time zone,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: sms_providers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sms_providers (
    id text NOT NULL,
    "providerKey" text NOT NULL,
    "displayName" text NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    priority integer DEFAULT 100 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: social_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_actions (
    id text NOT NULL,
    "actorId" text NOT NULL,
    "targetId" text NOT NULL,
    type text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    message text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: social_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_comments (
    id text NOT NULL,
    "postId" text NOT NULL,
    "userId" text NOT NULL,
    content text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: social_likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_likes (
    id text NOT NULL,
    "postId" text NOT NULL,
    "userId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: social_posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_posts (
    id text NOT NULL,
    "userId" text NOT NULL,
    "fortuneId" text,
    content text NOT NULL,
    "postType" text NOT NULL,
    "fortuneType" text,
    "isPublic" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "imageUrl" text,
    "isAuto" boolean DEFAULT false NOT NULL,
    "audioUrl" text,
    "youtubeUrl" text
);


--
-- Name: sos_game_chats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sos_game_chats (
    id text NOT NULL,
    "gameId" text NOT NULL,
    "userId" text NOT NULL,
    "userName" text NOT NULL,
    message text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sos_game_viewers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sos_game_viewers (
    id text NOT NULL,
    "gameId" text NOT NULL,
    "userId" text NOT NULL,
    "userName" text NOT NULL,
    "joinedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sos_games; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sos_games (
    id text NOT NULL,
    "gridSize" integer DEFAULT 6 NOT NULL,
    "player1Id" text NOT NULL,
    "player2Id" text,
    "isAI" boolean DEFAULT false NOT NULL,
    "betAmount" integer DEFAULT 0 NOT NULL,
    "betCurrency" text DEFAULT 'FREE'::text NOT NULL,
    board text DEFAULT '[]'::text NOT NULL,
    lines text DEFAULT '[]'::text NOT NULL,
    "currentTurn" integer DEFAULT 1 NOT NULL,
    "player1Score" integer DEFAULT 0 NOT NULL,
    "player2Score" integer DEFAULT 0 NOT NULL,
    status text DEFAULT 'waiting'::text NOT NULL,
    "winnerId" text,
    "player1Name" text DEFAULT 'Oyuncu 1'::text NOT NULL,
    "player2Name" text DEFAULT 'Oyuncu 2'::text NOT NULL,
    "turnTimer" integer DEFAULT 0 NOT NULL,
    "chatEnabled" boolean DEFAULT true NOT NULL,
    "lastMoveAt" timestamp(3) without time zone,
    "disconnectedPlayerId" text,
    "player1LastSeen" timestamp(3) without time zone,
    "player2LastSeen" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: store_purchases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.store_purchases (
    id text NOT NULL,
    "userId" text NOT NULL,
    provider text DEFAULT 'google_play'::text NOT NULL,
    "productId" text NOT NULL,
    "purchaseToken" text NOT NULL,
    "orderId" text,
    status text DEFAULT 'pending'::text NOT NULL,
    "failureReason" text,
    "rawResponse" jsonb,
    "grantedType" text,
    "grantedAmount" integer DEFAULT 0 NOT NULL,
    "ledgerTxId" text,
    "verifiedAt" timestamp(3) without time zone,
    "grantedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: stream_bans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stream_bans (
    id text NOT NULL,
    "streamId" text NOT NULL,
    "bannedUserId" text NOT NULL,
    reason text,
    "bannedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: stream_co_broadcasters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stream_co_broadcasters (
    id text NOT NULL,
    "streamId" text NOT NULL,
    "userId" text NOT NULL,
    status text DEFAULT 'invited'::text NOT NULL,
    "isMuted" boolean DEFAULT false NOT NULL,
    "isVideoOff" boolean DEFAULT false NOT NULL,
    "invitedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "joinedAt" timestamp(3) without time zone,
    "leftAt" timestamp(3) without time zone
);


--
-- Name: stream_fortune_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stream_fortune_requests (
    id text NOT NULL,
    "streamId" text NOT NULL,
    "userId" text NOT NULL,
    "typeId" text,
    nickname text,
    "isHidden" boolean DEFAULT false NOT NULL,
    question text,
    "jetonAmount" integer DEFAULT 0 NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    "refundedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "selectedAt" timestamp(3) without time zone,
    "completedAt" timestamp(3) without time zone
);


--
-- Name: stream_gifts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stream_gifts (
    id text NOT NULL,
    "streamId" text NOT NULL,
    "senderId" text NOT NULL,
    "giftTypeId" text NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    "totalPrice" integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "receiverAmount" integer DEFAULT 0 NOT NULL,
    "siteAmount" integer DEFAULT 0 NOT NULL
);


--
-- Name: stream_moderators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stream_moderators (
    id text NOT NULL,
    "streamId" text NOT NULL,
    "userId" text NOT NULL,
    "addedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: stream_muted_viewers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stream_muted_viewers (
    id text NOT NULL,
    "streamId" text NOT NULL,
    "viewerId" text NOT NULL,
    "mutedBy" text NOT NULL,
    reason text,
    "mutedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "expiresAt" timestamp(3) without time zone
);


--
-- Name: support_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.support_messages (
    id text NOT NULL,
    "ticketId" text NOT NULL,
    "senderId" text NOT NULL,
    "senderRole" text DEFAULT 'user'::text NOT NULL,
    body text NOT NULL,
    "isInternal" boolean DEFAULT false NOT NULL,
    attachments jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: support_tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.support_tickets (
    id text NOT NULL,
    "userId" text NOT NULL,
    subject text NOT NULL,
    category text DEFAULT 'general'::text NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    priority text DEFAULT 'normal'::text NOT NULL,
    "assignedTo" text,
    "lastMessageAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    metadata jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "relatedId" text,
    "relatedType" text
);


--
-- Name: supporter_levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supporter_levels (
    id text NOT NULL,
    "userId" text NOT NULL,
    "broadcasterId" text NOT NULL,
    "totalContributed" integer DEFAULT 0 NOT NULL,
    level integer DEFAULT 0 NOT NULL,
    "levelName" text,
    "lastContributedAt" timestamp(3) without time zone,
    metadata jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: team_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_members (
    id text NOT NULL,
    "teamId" text NOT NULL,
    "userId" text NOT NULL,
    role text DEFAULT 'member'::text NOT NULL,
    points integer DEFAULT 0 NOT NULL,
    "joinedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teams (
    id text NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    "ownerId" text NOT NULL,
    description text,
    "logoUrl" text,
    "memberCount" integer DEFAULT 1 NOT NULL,
    "totalPoints" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    metadata jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: teller_awards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teller_awards (
    id text NOT NULL,
    "tellerId" text NOT NULL,
    "awardType" text NOT NULL,
    title text,
    "awardedBy" text,
    "startDate" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "endDate" timestamp(3) without time zone NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: teller_chat_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teller_chat_messages (
    id text NOT NULL,
    "chatSessionId" text NOT NULL,
    "senderId" text NOT NULL,
    "senderType" text NOT NULL,
    content text NOT NULL,
    "messageType" text DEFAULT 'text'::text NOT NULL,
    "imageUrl" text,
    "isRead" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: teller_chat_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teller_chat_sessions (
    id text NOT NULL,
    "liveSessionId" text NOT NULL,
    "userId" text NOT NULL,
    "tellerId" text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "closedAt" timestamp(3) without time zone
);


--
-- Name: teller_gifts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teller_gifts (
    id text NOT NULL,
    "tellerId" text NOT NULL,
    "senderId" text NOT NULL,
    "giftTypeId" text NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    "totalPrice" integer NOT NULL,
    message text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: teller_warnings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teller_warnings (
    id text NOT NULL,
    "tellerId" text NOT NULL,
    reason text NOT NULL,
    "issuedBy" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: ticker_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ticker_messages (
    id text NOT NULL,
    text text NOT NULL,
    icon text DEFAULT '✨'::text NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: tiktok_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tiktok_categories (
    id text NOT NULL,
    title text NOT NULL,
    slug text NOT NULL,
    description text,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: tiktok_videos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tiktok_videos (
    id text NOT NULL,
    "tiktokUrl" text NOT NULL,
    "tiktokId" text,
    title text,
    "authorName" text,
    "authorAvatar" text,
    "thumbnailUrl" text,
    "embedHtml" text,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "categoryId" text
);


--
-- Name: topup_bonus_tiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.topup_bonus_tiers (
    id text NOT NULL,
    label text,
    "minAmount" integer NOT NULL,
    "bonusPercent" double precision DEFAULT 0 NOT NULL,
    currency text DEFAULT 'all'::text NOT NULL,
    "sourceType" text DEFAULT 'all'::text NOT NULL,
    "maxBonus" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: tournament_matches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tournament_matches (
    id text NOT NULL,
    "roundId" text NOT NULL,
    "matchOrder" integer DEFAULT 1 NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    "side1Id" text,
    "side1Name" text,
    "side1Score" integer DEFAULT 0 NOT NULL,
    "side2Id" text,
    "side2Name" text,
    "side2Score" integer DEFAULT 0 NOT NULL,
    "winnerId" text,
    "startedAt" timestamp(3) without time zone,
    "endedAt" timestamp(3) without time zone,
    "pkBattleId" text,
    notes text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone
);


--
-- Name: tournament_rounds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tournament_rounds (
    id text NOT NULL,
    "tournamentId" text NOT NULL,
    "roundNumber" integer DEFAULT 1 NOT NULL,
    name text,
    stage text,
    status text DEFAULT 'pending'::text NOT NULL,
    "startDate" timestamp(3) without time zone,
    "endDate" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: translations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.translations (
    id text NOT NULL,
    "languageCode" text NOT NULL,
    "translationKey" text NOT NULL,
    "translationValue" text NOT NULL
);


--
-- Name: trend_video_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trend_video_categories (
    id text NOT NULL,
    title text NOT NULL,
    slug text NOT NULL,
    description text,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: trend_videos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trend_videos (
    id text NOT NULL,
    "categoryId" text NOT NULL,
    title text NOT NULL,
    "youtubeId" text NOT NULL,
    "thumbnailUrl" text,
    "channelName" text,
    duration text,
    "viewCount" integer DEFAULT 0 NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: trending_topics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trending_topics (
    id text NOT NULL,
    title text NOT NULL,
    slug text NOT NULL,
    category text NOT NULL,
    description text,
    image text,
    icon text,
    "trendScore" integer DEFAULT 0 NOT NULL,
    "viewCount" integer DEFAULT 0 NOT NULL,
    "likeCount" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "isPinned" boolean DEFAULT false NOT NULL,
    "relatedUrl" text,
    tags text,
    "startDate" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "endDate" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: trtc_webhook_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trtc_webhook_logs (
    id text NOT NULL,
    "eventGroupId" integer NOT NULL,
    "eventType" integer NOT NULL,
    "sdkAppId" integer NOT NULL,
    "roomId" text,
    "userId" text,
    payload text NOT NULL,
    "processedOk" boolean DEFAULT true NOT NULL,
    "errorMessage" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_achievements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_achievements (
    id text NOT NULL,
    "userId" text NOT NULL,
    "achievementId" text NOT NULL,
    "earnedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    progress integer DEFAULT 0 NOT NULL,
    "isCompleted" boolean DEFAULT false NOT NULL
);


--
-- Name: user_blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_blocks (
    id text NOT NULL,
    "blockerId" text NOT NULL,
    "blockedId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_daily_activity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_daily_activity (
    id text NOT NULL,
    "userId" text NOT NULL,
    date date NOT NULL,
    "minutesSpent" integer DEFAULT 0 NOT NULL,
    "fortunesViewed" integer DEFAULT 0 NOT NULL,
    "postsCreated" integer DEFAULT 0 NOT NULL,
    "messagesCount" integer DEFAULT 0 NOT NULL,
    "streamsWatched" integer DEFAULT 0 NOT NULL,
    "creditsSpent" integer DEFAULT 0 NOT NULL,
    "creditsEarned" integer DEFAULT 0 NOT NULL
);


--
-- Name: user_devices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_devices (
    id text NOT NULL,
    "userId" text NOT NULL,
    token text NOT NULL,
    platform text DEFAULT 'android'::text NOT NULL,
    "appVersion" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: user_fortune_streaks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_fortune_streaks (
    id text NOT NULL,
    "userId" text NOT NULL,
    "currentStreak" integer DEFAULT 0 NOT NULL,
    "longestStreak" integer DEFAULT 0 NOT NULL,
    "lastFortuneDate" timestamp(3) without time zone,
    "totalFortunes" integer DEFAULT 0 NOT NULL
);


--
-- Name: user_game_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_game_profiles (
    id text NOT NULL,
    "userId" text NOT NULL,
    "totalJetons" integer DEFAULT 0 NOT NULL,
    "totalGames" integer DEFAULT 0 NOT NULL,
    level integer DEFAULT 1 NOT NULL,
    "levelTitle" text DEFAULT 'Yeni Üye'::text NOT NULL,
    "dailySpinsUsed" integer DEFAULT 0 NOT NULL,
    "lastSpinDate" date,
    "referralCode" text,
    "referralCount" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: user_hourly_activity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_hourly_activity (
    id text NOT NULL,
    "userId" text NOT NULL,
    hour integer NOT NULL,
    "totalMinutes" integer DEFAULT 0 NOT NULL,
    "loginCount" integer DEFAULT 0 NOT NULL
);


--
-- Name: user_login_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_login_sessions (
    id text NOT NULL,
    "userId" text NOT NULL,
    "loginAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "logoutAt" timestamp(3) without time zone,
    duration integer DEFAULT 0 NOT NULL,
    "deviceType" text,
    browser text
);


--
-- Name: user_mission_progress; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_mission_progress (
    id text NOT NULL,
    "userId" text NOT NULL,
    "missionId" text NOT NULL,
    "dayKey" text NOT NULL,
    progress integer DEFAULT 0 NOT NULL,
    completed boolean DEFAULT false NOT NULL,
    claimed boolean DEFAULT false NOT NULL,
    "updatedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_online_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_online_events (
    id text NOT NULL,
    "userId" text NOT NULL,
    username text NOT NULL,
    "avatarUrl" text,
    "effectId" text,
    "effectUrl" text,
    "effectType" text,
    "durationMs" integer DEFAULT 4000 NOT NULL,
    "animationType" text DEFAULT 'slide_lr'::text NOT NULL,
    tier text DEFAULT 'gold'::text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_permission_overrides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_permission_overrides (
    id text NOT NULL,
    "userId" text NOT NULL,
    "permissionKey" text NOT NULL,
    granted boolean DEFAULT true NOT NULL,
    "grantedBy" text NOT NULL,
    reason text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: user_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_reports (
    id text NOT NULL,
    "reporterId" text NOT NULL,
    "reportedId" text NOT NULL,
    reason text NOT NULL,
    details text,
    status text DEFAULT 'pending'::text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: user_stories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_stories (
    id text NOT NULL,
    "userId" text NOT NULL,
    "mediaUrl" text NOT NULL,
    "mediaType" text DEFAULT 'image'::text NOT NULL,
    caption text,
    "viewCount" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_timeline_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_timeline_events (
    id text NOT NULL,
    "userId" text NOT NULL,
    type text NOT NULL,
    title text NOT NULL,
    description text,
    metadata text,
    "occurredAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_token_revocations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_token_revocations (
    "userId" text NOT NULL,
    "revokedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    reason text,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: user_vip_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_vip_preferences (
    id text NOT NULL,
    "userId" text NOT NULL,
    "hideVipBadge" boolean DEFAULT false NOT NULL,
    "hideOnlineStatus" boolean DEFAULT false NOT NULL,
    "hideLastSeen" boolean DEFAULT false NOT NULL,
    "hideProfileVisit" boolean DEFAULT false NOT NULL,
    "hiddenRoomEntry" boolean DEFAULT false NOT NULL,
    "hideVipStatus" boolean DEFAULT false NOT NULL,
    "disableEntranceEffects" boolean DEFAULT false NOT NULL,
    "muteOthersEntrance" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: user_warnings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_warnings (
    id text NOT NULL,
    "userId" text NOT NULL,
    "adminId" text NOT NULL,
    "adminName" text,
    reason text NOT NULL,
    severity text DEFAULT 'info'::text NOT NULL,
    "expiresAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id text NOT NULL,
    email text NOT NULL,
    "emailVerified" timestamp(3) without time zone,
    password text,
    name text NOT NULL,
    username text,
    phone text,
    image text,
    "preferredLanguage" text DEFAULT 'tr'::text NOT NULL,
    credits integer DEFAULT 50 NOT NULL,
    role text DEFAULT 'user'::text NOT NULL,
    membership text DEFAULT 'basic'::text NOT NULL,
    "membershipExpiresAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "referralCode" text,
    "referralCreditsEarned" integer DEFAULT 0 NOT NULL,
    "referredById" text,
    bio text,
    "birthDate" timestamp(3) without time zone,
    "birthTime" text,
    "zodiacSign" text,
    "risingSign" text,
    "favoriteTeam" text,
    "lastHoroscopeDate" timestamp(3) without time zone,
    "messagePrivacy" text DEFAULT 'everyone'::text NOT NULL,
    "hideProfileViews" boolean DEFAULT false NOT NULL,
    theme text DEFAULT 'mystical'::text NOT NULL,
    "jetonBalance" integer DEFAULT 0 NOT NULL,
    "specialBadges" text,
    "profileEffect" text,
    "profileFrameId" text,
    "adminAssignedFrameId" text,
    "withdrawalLimit" integer DEFAULT 0 NOT NULL,
    "totalTimeSpentMinutes" integer DEFAULT 0 NOT NULL,
    "lastActiveAt" timestamp(3) without time zone,
    "activeDeviceToken" text,
    xp integer DEFAULT 0 NOT NULL,
    level integer DEFAULT 1 NOT NULL,
    "loginStreak" integer DEFAULT 0 NOT NULL,
    "lastLoginRewardDate" date,
    "isBot" boolean DEFAULT false NOT NULL,
    "cfcBalance" integer DEFAULT 0 NOT NULL,
    city text,
    country text DEFAULT 'TR'::text,
    "avatarAccessoryIds" text,
    "chatBubbleId" text,
    "entranceEffectId" text,
    "micFrameId" text,
    "nameEffect" text,
    "lastOnlineEventAt" timestamp(3) without time zone,
    "premiumEntranceAnimationType" text,
    "premiumEntranceDurationMs" integer,
    "premiumEntranceEffectId" text,
    "premiumEntranceEnabled" boolean DEFAULT false NOT NULL,
    "premiumEntranceRequireGold" boolean DEFAULT true NOT NULL,
    "banReason" text,
    "bannedAt" timestamp(3) without time zone,
    "bannedBy" text,
    "bannedUntil" timestamp(3) without time zone,
    "canBroadcast" boolean DEFAULT true NOT NULL,
    "canChat" boolean DEFAULT true NOT NULL,
    "canCreateRoom" boolean DEFAULT true NOT NULL,
    "canPK" boolean DEFAULT true NOT NULL,
    "canSendGift" boolean DEFAULT true NOT NULL,
    "isBanned" boolean DEFAULT false NOT NULL,
    "isVerifiedUser" boolean DEFAULT false NOT NULL,
    "phoneVerified" boolean DEFAULT false NOT NULL,
    "customUserId" text,
    "vipXp" integer DEFAULT 0 NOT NULL,
    "vipTitle" text,
    "frozenAt" timestamp(3) without time zone,
    "frozenReason" text,
    "hiddenFromDiscovery" boolean DEFAULT false NOT NULL,
    "isFrozen" boolean DEFAULT false NOT NULL,
    "warningCount" integer DEFAULT 0 NOT NULL,
    "discoveryPriority" integer DEFAULT 0 NOT NULL,
    hobbies text,
    latitude double precision,
    "locationEnabled" boolean DEFAULT false NOT NULL,
    longitude double precision,
    "showAge" boolean DEFAULT true NOT NULL,
    "showCity" boolean DEFAULT true NOT NULL,
    "showDistance" boolean DEFAULT true NOT NULL,
    "showLastActive" boolean DEFAULT true NOT NULL,
    "socialLinks" text,
    "socialLinksPublic" boolean DEFAULT false NOT NULL,
    CONSTRAINT users_credits_nonneg CHECK ((credits >= 0)),
    CONSTRAINT "users_jetonBalance_nonneg" CHECK (("jetonBalance" >= 0))
);


--
-- Name: verification_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.verification_tokens (
    identifier text NOT NULL,
    token text NOT NULL,
    expires timestamp(3) without time zone NOT NULL
);


--
-- Name: verifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.verifications (
    id text NOT NULL,
    "userId" text NOT NULL,
    type text DEFAULT 'identity'::text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    "fullName" text,
    "documentType" text,
    "documentUrls" jsonb,
    note text,
    "reviewNote" text,
    "reviewedBy" text,
    "reviewedAt" timestamp(3) without time zone,
    metadata jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: video_stream_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.video_stream_comments (
    id text NOT NULL,
    "streamId" text NOT NULL,
    "userId" text NOT NULL,
    content text NOT NULL,
    nickname text,
    "isHidden" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: video_stream_likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.video_stream_likes (
    id text NOT NULL,
    "streamId" text NOT NULL,
    "userId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: video_stream_signals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.video_stream_signals (
    id text NOT NULL,
    "streamId" text NOT NULL,
    "senderId" text NOT NULL,
    "receiverId" text,
    "signalType" text NOT NULL,
    "signalData" text NOT NULL,
    processed boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: video_stream_viewers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.video_stream_viewers (
    id text NOT NULL,
    "streamId" text NOT NULL,
    "viewerId" text NOT NULL,
    "viewerName" text,
    nickname text,
    "isHidden" boolean DEFAULT false NOT NULL,
    "joinedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "leftAt" timestamp(3) without time zone
);


--
-- Name: video_streams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.video_streams (
    id text NOT NULL,
    "userId" text NOT NULL,
    title text,
    description text,
    status text DEFAULT 'live'::text NOT NULL,
    "viewerCount" integer DEFAULT 0 NOT NULL,
    "likeCount" integer DEFAULT 0 NOT NULL,
    "roomId" text NOT NULL,
    category text,
    "thumbnailUrl" text,
    "broadcastImage" text,
    "isImageMode" boolean DEFAULT false NOT NULL,
    "startedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "endedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "autoClosedAt" timestamp(3) without time zone,
    "lastGiftAt" timestamp(3) without time zone,
    "backgroundUrl" text,
    "lastMediaAt" timestamp(3) without time zone
);


--
-- Name: vip_xp_ledger; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vip_xp_ledger (
    id text NOT NULL,
    "userId" text NOT NULL,
    amount integer NOT NULL,
    source text NOT NULL,
    "refId" text,
    note text,
    "balanceAfter" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: voice_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.voice_sessions (
    id text NOT NULL,
    "roomId" text NOT NULL,
    "userId" text NOT NULL,
    "userName" text NOT NULL,
    "joinedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "lastPing" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "trtcUid" integer DEFAULT 0 NOT NULL
);


--
-- Name: voice_signals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.voice_signals (
    id text NOT NULL,
    "roomId" text NOT NULL,
    "fromUserId" text NOT NULL,
    "fromUserName" text NOT NULL,
    "toUserId" text,
    type text NOT NULL,
    data text,
    processed boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: weekly_dream_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.weekly_dream_reports (
    id text NOT NULL,
    "userId" text NOT NULL,
    "weekStart" date NOT NULL,
    "weekEnd" date NOT NULL,
    "reportContent" text NOT NULL,
    "dreamCount" integer DEFAULT 0 NOT NULL,
    "topSymbols" text[] DEFAULT ARRAY[]::text[],
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: weekly_tournament_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.weekly_tournament_entries (
    id text NOT NULL,
    "tournamentId" text NOT NULL,
    "userId" text NOT NULL,
    score integer DEFAULT 0 NOT NULL,
    rank integer,
    rewarded boolean DEFAULT false NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: weekly_tournaments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.weekly_tournaments (
    id text NOT NULL,
    "weekStart" timestamp(3) without time zone NOT NULL,
    "weekEnd" timestamp(3) without time zone NOT NULL,
    type text DEFAULT 'jeton_spend'::text NOT NULL,
    title text NOT NULL,
    description text,
    status text DEFAULT 'active'::text NOT NULL,
    rewards text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    category text,
    "coverImage" text,
    "createdBy" text,
    "eliminationType" text,
    "maxParticipants" integer,
    "minParticipants" integer,
    "registrationEnd" timestamp(3) without time zone,
    "registrationStart" timestamp(3) without time zone,
    "rewardedAt" timestamp(3) without time zone,
    "roundCount" integer DEFAULT 1,
    "scoringType" text,
    "updatedAt" timestamp(3) without time zone,
    visibility text DEFAULT 'public'::text
);


--
-- Name: withdrawal_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.withdrawal_requests (
    id text NOT NULL,
    "userId" text NOT NULL,
    amount integer NOT NULL,
    "amountTL" double precision NOT NULL,
    method text NOT NULL,
    "accountDetails" text,
    status text DEFAULT 'pending'::text NOT NULL,
    "adminNote" text,
    "processedBy" text,
    "processedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "agencyApprovedAt" timestamp(3) without time zone,
    "agencyApprovedBy" text,
    "agencyId" text,
    "agencyNote" text,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: account_deletions account_deletions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_deletions
    ADD CONSTRAINT account_deletions_pkey PRIMARY KEY (id);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: achievements achievements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.achievements
    ADD CONSTRAINT achievements_pkey PRIMARY KEY (id);


--
-- Name: activity_feed_config activity_feed_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_feed_config
    ADD CONSTRAINT activity_feed_config_pkey PRIMARY KEY (id);


--
-- Name: ad_networks ad_networks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ad_networks
    ADD CONSTRAINT ad_networks_pkey PRIMARY KEY (id);


--
-- Name: ad_placements ad_placements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ad_placements
    ADD CONSTRAINT ad_placements_pkey PRIMARY KEY (id);


--
-- Name: admin_popups admin_popups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_popups
    ADD CONSTRAINT admin_popups_pkey PRIMARY KEY (id);


--
-- Name: admin_user_actions admin_user_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_user_actions
    ADD CONSTRAINT admin_user_actions_pkey PRIMARY KEY (id);


--
-- Name: agencies agencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agencies
    ADD CONSTRAINT agencies_pkey PRIMARY KEY (id);


--
-- Name: agency_bonus_rules agency_bonus_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_bonus_rules
    ADD CONSTRAINT agency_bonus_rules_pkey PRIMARY KEY (id);


--
-- Name: agency_commission_rules agency_commission_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_commission_rules
    ADD CONSTRAINT agency_commission_rules_pkey PRIMARY KEY (id);


--
-- Name: agency_earnings agency_earnings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_earnings
    ADD CONSTRAINT agency_earnings_pkey PRIMARY KEY (id);


--
-- Name: agency_leave_requests agency_leave_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_leave_requests
    ADD CONSTRAINT agency_leave_requests_pkey PRIMARY KEY (id);


--
-- Name: agency_penalties agency_penalties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_penalties
    ADD CONSTRAINT agency_penalties_pkey PRIMARY KEY (id);


--
-- Name: agency_tasks agency_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_tasks
    ADD CONSTRAINT agency_tasks_pkey PRIMARY KEY (id);


--
-- Name: agency_users agency_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_users
    ADD CONSTRAINT agency_users_pkey PRIMARY KEY (id);


--
-- Name: agency_wallet_transactions agency_wallet_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_wallet_transactions
    ADD CONSTRAINT agency_wallet_transactions_pkey PRIMARY KEY (id);


--
-- Name: agency_wallets agency_wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_wallets
    ADD CONSTRAINT agency_wallets_pkey PRIMARY KEY (id);


--
-- Name: animation_assignments animation_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animation_assignments
    ADD CONSTRAINT animation_assignments_pkey PRIMARY KEY (id);


--
-- Name: animation_membership_defaults animation_membership_defaults_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animation_membership_defaults
    ADD CONSTRAINT animation_membership_defaults_pkey PRIMARY KEY (id);


--
-- Name: animation_playback_logs animation_playback_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animation_playback_logs
    ADD CONSTRAINT animation_playback_logs_pkey PRIMARY KEY (id);


--
-- Name: animations animations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animations
    ADD CONSTRAINT animations_pkey PRIMARY KEY (id);


--
-- Name: anonymous_fortunes anonymous_fortunes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anonymous_fortunes
    ADD CONSTRAINT anonymous_fortunes_pkey PRIMARY KEY (id);


--
-- Name: anonymous_users anonymous_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anonymous_users
    ADD CONSTRAINT anonymous_users_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: avatar_accessories avatar_accessories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.avatar_accessories
    ADD CONSTRAINT avatar_accessories_pkey PRIMARY KEY (id);


--
-- Name: bana_ozel_history bana_ozel_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bana_ozel_history
    ADD CONSTRAINT bana_ozel_history_pkey PRIMARY KEY (id);


--
-- Name: bana_ozel_items bana_ozel_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bana_ozel_items
    ADD CONSTRAINT bana_ozel_items_pkey PRIMARY KEY (id);


--
-- Name: blog_categories blog_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blog_categories
    ADD CONSTRAINT blog_categories_pkey PRIMARY KEY (id);


--
-- Name: blog_comments blog_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blog_comments
    ADD CONSTRAINT blog_comments_pkey PRIMARY KEY (id);


--
-- Name: blog_favorites blog_favorites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blog_favorites
    ADD CONSTRAINT blog_favorites_pkey PRIMARY KEY (id);


--
-- Name: blog_likes blog_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blog_likes
    ADD CONSTRAINT blog_likes_pkey PRIMARY KEY (id);


--
-- Name: blog_posts blog_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blog_posts
    ADD CONSTRAINT blog_posts_pkey PRIMARY KEY (id);


--
-- Name: bot_profiles bot_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_profiles
    ADD CONSTRAINT bot_profiles_pkey PRIMARY KEY (id);


--
-- Name: broadcast_images broadcast_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.broadcast_images
    ADD CONSTRAINT broadcast_images_pkey PRIMARY KEY (id);


--
-- Name: celebrities celebrities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.celebrities
    ADD CONSTRAINT celebrities_pkey PRIMARY KEY (id);


--
-- Name: celebrity_follows celebrity_follows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.celebrity_follows
    ADD CONSTRAINT celebrity_follows_pkey PRIMARY KEY (id);


--
-- Name: celebrity_post_comments celebrity_post_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.celebrity_post_comments
    ADD CONSTRAINT celebrity_post_comments_pkey PRIMARY KEY (id);


--
-- Name: celebrity_post_likes celebrity_post_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.celebrity_post_likes
    ADD CONSTRAINT celebrity_post_likes_pkey PRIMARY KEY (id);


--
-- Name: celebrity_posts celebrity_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.celebrity_posts
    ADD CONSTRAINT celebrity_posts_pkey PRIMARY KEY (id);


--
-- Name: cfc_contests cfc_contests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cfc_contests
    ADD CONSTRAINT cfc_contests_pkey PRIMARY KEY (id);


--
-- Name: cfc_participants cfc_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cfc_participants
    ADD CONSTRAINT cfc_participants_pkey PRIMARY KEY (id);


--
-- Name: cfc_payment_requests cfc_payment_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cfc_payment_requests
    ADD CONSTRAINT cfc_payment_requests_pkey PRIMARY KEY (id);


--
-- Name: cfc_score_logs cfc_score_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cfc_score_logs
    ADD CONSTRAINT cfc_score_logs_pkey PRIMARY KEY (id);


--
-- Name: cfc_seasons cfc_seasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cfc_seasons
    ADD CONSTRAINT cfc_seasons_pkey PRIMARY KEY (id);


--
-- Name: cfc_teams cfc_teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cfc_teams
    ADD CONSTRAINT cfc_teams_pkey PRIMARY KEY (id);


--
-- Name: chat_bans chat_bans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_bans
    ADD CONSTRAINT chat_bans_pkey PRIMARY KEY (id);


--
-- Name: chat_bubble_skins chat_bubble_skins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_bubble_skins
    ADD CONSTRAINT chat_bubble_skins_pkey PRIMARY KEY (id);


--
-- Name: chat_messages chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_pkey PRIMARY KEY (id);


--
-- Name: chat_mutes chat_mutes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_mutes
    ADD CONSTRAINT chat_mutes_pkey PRIMARY KEY (id);


--
-- Name: chat_presences chat_presences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_presences
    ADD CONSTRAINT chat_presences_pkey PRIMARY KEY (id);


--
-- Name: chat_room_gifts chat_room_gifts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_gifts
    ADD CONSTRAINT chat_room_gifts_pkey PRIMARY KEY (id);


--
-- Name: chat_rooms chat_rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_rooms
    ADD CONSTRAINT chat_rooms_pkey PRIMARY KEY (id);


--
-- Name: chat_speak_blocks chat_speak_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_speak_blocks
    ADD CONSTRAINT chat_speak_blocks_pkey PRIMARY KEY (id);


--
-- Name: chat_speak_requests chat_speak_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_speak_requests
    ADD CONSTRAINT chat_speak_requests_pkey PRIMARY KEY (id);


--
-- Name: chat_user_roles chat_user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_user_roles
    ADD CONSTRAINT chat_user_roles_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: credit_packages credit_packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_packages
    ADD CONSTRAINT credit_packages_pkey PRIMARY KEY (id);


--
-- Name: credit_transactions credit_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_transactions
    ADD CONSTRAINT credit_transactions_pkey PRIMARY KEY (id);


--
-- Name: currency_config currency_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency_config
    ADD CONSTRAINT currency_config_pkey PRIMARY KEY (id);


--
-- Name: custom_badges custom_badges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_badges
    ADD CONSTRAINT custom_badges_pkey PRIMARY KEY (id);


--
-- Name: daily_login_rewards daily_login_rewards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_login_rewards
    ADD CONSTRAINT daily_login_rewards_pkey PRIMARY KEY (id);


--
-- Name: daily_quests daily_quests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_quests
    ADD CONSTRAINT daily_quests_pkey PRIMARY KEY (id);


--
-- Name: daily_rewards daily_rewards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_rewards
    ADD CONSTRAINT daily_rewards_pkey PRIMARY KEY (id);


--
-- Name: daily_tasks daily_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_tasks
    ADD CONSTRAINT daily_tasks_pkey PRIMARY KEY (id);


--
-- Name: direct_messages direct_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.direct_messages
    ADD CONSTRAINT direct_messages_pkey PRIMARY KEY (id);


--
-- Name: dream_comments dream_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_comments
    ADD CONSTRAINT dream_comments_pkey PRIMARY KEY (id);


--
-- Name: dream_contest_entries dream_contest_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_contest_entries
    ADD CONSTRAINT dream_contest_entries_pkey PRIMARY KEY (id);


--
-- Name: dream_contest_votes dream_contest_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_contest_votes
    ADD CONSTRAINT dream_contest_votes_pkey PRIMARY KEY (id);


--
-- Name: dream_contests dream_contests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_contests
    ADD CONSTRAINT dream_contests_pkey PRIMARY KEY (id);


--
-- Name: dream_diary_entries dream_diary_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_diary_entries
    ADD CONSTRAINT dream_diary_entries_pkey PRIMARY KEY (id);


--
-- Name: dream_favorites dream_favorites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_favorites
    ADD CONSTRAINT dream_favorites_pkey PRIMARY KEY (id);


--
-- Name: dream_interpretations dream_interpretations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_interpretations
    ADD CONSTRAINT dream_interpretations_pkey PRIMARY KEY (id);


--
-- Name: dream_symbols dream_symbols_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_symbols
    ADD CONSTRAINT dream_symbols_pkey PRIMARY KEY (id);


--
-- Name: dream_views dream_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_views
    ADD CONSTRAINT dream_views_pkey PRIMARY KEY (id);


--
-- Name: effect_rules effect_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.effect_rules
    ADD CONSTRAINT effect_rules_pkey PRIMARY KEY (id);


--
-- Name: email_verification_tokens email_verification_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_verification_tokens
    ADD CONSTRAINT email_verification_tokens_pkey PRIMARY KEY (id);


--
-- Name: emoji_packs emoji_packs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emoji_packs
    ADD CONSTRAINT emoji_packs_pkey PRIMARY KEY (id);


--
-- Name: entrance_effects entrance_effects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entrance_effects
    ADD CONSTRAINT entrance_effects_pkey PRIMARY KEY (id);


--
-- Name: fan_club_members fan_club_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fan_club_members
    ADD CONSTRAINT fan_club_members_pkey PRIMARY KEY (id);


--
-- Name: fan_club_poll_votes fan_club_poll_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fan_club_poll_votes
    ADD CONSTRAINT fan_club_poll_votes_pkey PRIMARY KEY (id);


--
-- Name: fan_club_polls fan_club_polls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fan_club_polls
    ADD CONSTRAINT fan_club_polls_pkey PRIMARY KEY (id);


--
-- Name: fan_club_post_likes fan_club_post_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fan_club_post_likes
    ADD CONSTRAINT fan_club_post_likes_pkey PRIMARY KEY (id);


--
-- Name: fan_club_posts fan_club_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fan_club_posts
    ADD CONSTRAINT fan_club_posts_pkey PRIMARY KEY (id);


--
-- Name: fan_clubs fan_clubs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fan_clubs
    ADD CONSTRAINT fan_clubs_pkey PRIMARY KEY (id);


--
-- Name: favorite_tellers favorite_tellers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorite_tellers
    ADD CONSTRAINT favorite_tellers_pkey PRIMARY KEY (id);


--
-- Name: feature_flags feature_flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feature_flags
    ADD CONSTRAINT feature_flags_pkey PRIMARY KEY (id);


--
-- Name: follows follows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows
    ADD CONSTRAINT follows_pkey PRIMARY KEY (id);


--
-- Name: fortune_ratings fortune_ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fortune_ratings
    ADD CONSTRAINT fortune_ratings_pkey PRIMARY KEY (id);


--
-- Name: fortune_request_types fortune_request_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fortune_request_types
    ADD CONSTRAINT fortune_request_types_pkey PRIMARY KEY (id);


--
-- Name: fortunes fortunes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fortunes
    ADD CONSTRAINT fortunes_pkey PRIMARY KEY (id);


--
-- Name: game_plays game_plays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_plays
    ADD CONSTRAINT game_plays_pkey PRIMARY KEY (id);


--
-- Name: game_room_chats game_room_chats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_room_chats
    ADD CONSTRAINT game_room_chats_pkey PRIMARY KEY (id);


--
-- Name: game_room_viewers game_room_viewers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_room_viewers
    ADD CONSTRAINT game_room_viewers_pkey PRIMARY KEY (id);


--
-- Name: game_rooms game_rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_rooms
    ADD CONSTRAINT game_rooms_pkey PRIMARY KEY (id);


--
-- Name: gift_battle_participants gift_battle_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gift_battle_participants
    ADD CONSTRAINT gift_battle_participants_pkey PRIMARY KEY (id);


--
-- Name: gift_battles gift_battles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gift_battles
    ADD CONSTRAINT gift_battles_pkey PRIMARY KEY (id);


--
-- Name: gift_box_entries gift_box_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gift_box_entries
    ADD CONSTRAINT gift_box_entries_pkey PRIMARY KEY (id);


--
-- Name: gift_boxes gift_boxes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gift_boxes
    ADD CONSTRAINT gift_boxes_pkey PRIMARY KEY (id);


--
-- Name: gift_collections gift_collections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gift_collections
    ADD CONSTRAINT gift_collections_pkey PRIMARY KEY (id);


--
-- Name: gift_combos gift_combos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gift_combos
    ADD CONSTRAINT gift_combos_pkey PRIMARY KEY (id);


--
-- Name: gift_events gift_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gift_events
    ADD CONSTRAINT gift_events_pkey PRIMARY KEY (id);


--
-- Name: gift_goals gift_goals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gift_goals
    ADD CONSTRAINT gift_goals_pkey PRIMARY KEY (id);


--
-- Name: gift_history gift_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gift_history
    ADD CONSTRAINT gift_history_pkey PRIMARY KEY (id);


--
-- Name: gift_missions gift_missions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gift_missions
    ADD CONSTRAINT gift_missions_pkey PRIMARY KEY (id);


--
-- Name: gift_queue gift_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gift_queue
    ADD CONSTRAINT gift_queue_pkey PRIMARY KEY (id);


--
-- Name: gift_types gift_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gift_types
    ADD CONSTRAINT gift_types_pkey PRIMARY KEY (id);


--
-- Name: hashtags hashtags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hashtags
    ADD CONSTRAINT hashtags_pkey PRIMARY KEY (id);


--
-- Name: homepage_buttons homepage_buttons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.homepage_buttons
    ADD CONSTRAINT homepage_buttons_pkey PRIMARY KEY (id);


--
-- Name: homepage_fortune_cards homepage_fortune_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.homepage_fortune_cards
    ADD CONSTRAINT homepage_fortune_cards_pkey PRIMARY KEY (id);


--
-- Name: idempotency_records idempotency_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.idempotency_records
    ADD CONSTRAINT idempotency_records_pkey PRIMARY KEY (id);


--
-- Name: integration_secrets integration_secrets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_secrets
    ADD CONSTRAINT integration_secrets_pkey PRIMARY KEY (id);


--
-- Name: integration_settings integration_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_settings
    ADD CONSTRAINT integration_settings_pkey PRIMARY KEY (id);


--
-- Name: invite_codes invite_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invite_codes
    ADD CONSTRAINT invite_codes_pkey PRIMARY KEY (id);


--
-- Name: ip_fortune_usage ip_fortune_usage_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ip_fortune_usage
    ADD CONSTRAINT ip_fortune_usage_pkey PRIMARY KEY (id);


--
-- Name: jeton_transactions jeton_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jeton_transactions
    ADD CONSTRAINT jeton_transactions_pkey PRIMARY KEY (id);


--
-- Name: leaderboard_configs leaderboard_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leaderboard_configs
    ADD CONSTRAINT leaderboard_configs_pkey PRIMARY KEY (id);


--
-- Name: leaderboard_entries leaderboard_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leaderboard_entries
    ADD CONSTRAINT leaderboard_entries_pkey PRIMARY KEY (id);


--
-- Name: leaderboard_periods leaderboard_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leaderboard_periods
    ADD CONSTRAINT leaderboard_periods_pkey PRIMARY KEY (id);


--
-- Name: leaderboard_rewards leaderboard_rewards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leaderboard_rewards
    ADD CONSTRAINT leaderboard_rewards_pkey PRIMARY KEY (id);


--
-- Name: ledger_entries ledger_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_entries
    ADD CONSTRAINT ledger_entries_pkey PRIMARY KEY (id);


--
-- Name: live_activities live_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_activities
    ADD CONSTRAINT live_activities_pkey PRIMARY KEY (id);


--
-- Name: live_fortune_tellers live_fortune_tellers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_fortune_tellers
    ADD CONSTRAINT live_fortune_tellers_pkey PRIMARY KEY (id);


--
-- Name: live_guest_invites live_guest_invites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_guest_invites
    ADD CONSTRAINT live_guest_invites_pkey PRIMARY KEY (id);


--
-- Name: live_guest_sessions live_guest_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_guest_sessions
    ADD CONSTRAINT live_guest_sessions_pkey PRIMARY KEY (id);


--
-- Name: live_session_messages live_session_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_session_messages
    ADD CONSTRAINT live_session_messages_pkey PRIMARY KEY (id);


--
-- Name: live_sessions live_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_sessions
    ADD CONSTRAINT live_sessions_pkey PRIMARY KEY (id);


--
-- Name: live_teller_reviews live_teller_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_teller_reviews
    ADD CONSTRAINT live_teller_reviews_pkey PRIMARY KEY (id);


--
-- Name: lucky_gift_rewards lucky_gift_rewards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lucky_gift_rewards
    ADD CONSTRAINT lucky_gift_rewards_pkey PRIMARY KEY (id);


--
-- Name: lucky_gift_tiers lucky_gift_tiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lucky_gift_tiers
    ADD CONSTRAINT lucky_gift_tiers_pkey PRIMARY KEY (id);


--
-- Name: membership_badges membership_badges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membership_badges
    ADD CONSTRAINT membership_badges_pkey PRIMARY KEY (id);


--
-- Name: membership_events membership_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membership_events
    ADD CONSTRAINT membership_events_pkey PRIMARY KEY (id);


--
-- Name: membership_features membership_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membership_features
    ADD CONSTRAINT membership_features_pkey PRIMARY KEY (id);


--
-- Name: membership_grants membership_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membership_grants
    ADD CONSTRAINT membership_grants_pkey PRIMARY KEY (id);


--
-- Name: membership_plans membership_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membership_plans
    ADD CONSTRAINT membership_plans_pkey PRIMARY KEY (id);


--
-- Name: membership_purchases membership_purchases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membership_purchases
    ADD CONSTRAINT membership_purchases_pkey PRIMARY KEY (id);


--
-- Name: membership_tier_defs membership_tier_defs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membership_tier_defs
    ADD CONSTRAINT membership_tier_defs_pkey PRIMARY KEY (id);


--
-- Name: membership_tier_features membership_tier_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membership_tier_features
    ADD CONSTRAINT membership_tier_features_pkey PRIMARY KEY (id);


--
-- Name: message_requests message_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_requests
    ADD CONSTRAINT message_requests_pkey PRIMARY KEY (id);


--
-- Name: mic_frames mic_frames_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mic_frames
    ADD CONSTRAINT mic_frames_pkey PRIMARY KEY (id);


--
-- Name: mini_games mini_games_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mini_games
    ADD CONSTRAINT mini_games_pkey PRIMARY KEY (id);


--
-- Name: name_effects name_effects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_effects
    ADD CONSTRAINT name_effects_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: okey_match_players okey_match_players_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.okey_match_players
    ADD CONSTRAINT okey_match_players_pkey PRIMARY KEY (id);


--
-- Name: okey_matches okey_matches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.okey_matches
    ADD CONSTRAINT okey_matches_pkey PRIMARY KEY (id);


--
-- Name: online_fal_buttons online_fal_buttons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_fal_buttons
    ADD CONSTRAINT online_fal_buttons_pkey PRIMARY KEY (id);


--
-- Name: online_fal_sections online_fal_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_fal_sections
    ADD CONSTRAINT online_fal_sections_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (id);


--
-- Name: payment_methods payment_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_methods
    ADD CONSTRAINT payment_methods_pkey PRIMARY KEY (id);


--
-- Name: payment_notifications payment_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_notifications
    ADD CONSTRAINT payment_notifications_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: phone_otps phone_otps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.phone_otps
    ADD CONSTRAINT phone_otps_pkey PRIMARY KEY (id);


--
-- Name: pk_bans pk_bans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pk_bans
    ADD CONSTRAINT pk_bans_pkey PRIMARY KEY (id);


--
-- Name: pk_battle_participants pk_battle_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pk_battle_participants
    ADD CONSTRAINT pk_battle_participants_pkey PRIMARY KEY (id);


--
-- Name: pk_battles pk_battles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pk_battles
    ADD CONSTRAINT pk_battles_pkey PRIMARY KEY (id);


--
-- Name: pk_events pk_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pk_events
    ADD CONSTRAINT pk_events_pkey PRIMARY KEY (id);


--
-- Name: pk_gifts pk_gifts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pk_gifts
    ADD CONSTRAINT pk_gifts_pkey PRIMARY KEY (id);


--
-- Name: pk_matches pk_matches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pk_matches
    ADD CONSTRAINT pk_matches_pkey PRIMARY KEY (id);


--
-- Name: pk_participants pk_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pk_participants
    ADD CONSTRAINT pk_participants_pkey PRIMARY KEY (id);


--
-- Name: pk_scores pk_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pk_scores
    ADD CONSTRAINT pk_scores_pkey PRIMARY KEY (id);


--
-- Name: pk_seats pk_seats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pk_seats
    ADD CONSTRAINT pk_seats_pkey PRIMARY KEY (id);


--
-- Name: pk_stats pk_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pk_stats
    ADD CONSTRAINT pk_stats_pkey PRIMARY KEY ("userId");


--
-- Name: platform_settings platform_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_settings
    ADD CONSTRAINT platform_settings_pkey PRIMARY KEY (id);


--
-- Name: profile_frames profile_frames_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_frames
    ADD CONSTRAINT profile_frames_pkey PRIMARY KEY (id);


--
-- Name: profile_views profile_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_views
    ADD CONSTRAINT profile_views_pkey PRIMARY KEY (id);


--
-- Name: profile_visits profile_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_visits
    ADD CONSTRAINT profile_visits_pkey PRIMARY KEY (id);


--
-- Name: push_notification_logs push_notification_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_notification_logs
    ADD CONSTRAINT push_notification_logs_pkey PRIMARY KEY (id);


--
-- Name: referral_commissions referral_commissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_commissions
    ADD CONSTRAINT referral_commissions_pkey PRIMARY KEY (id);


--
-- Name: referrals referrals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_pkey PRIMARY KEY (id);


--
-- Name: refund_requests refund_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refund_requests
    ADD CONSTRAINT refund_requests_pkey PRIMARY KEY (id);


--
-- Name: remote_configs remote_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remote_configs
    ADD CONSTRAINT remote_configs_pkey PRIMARY KEY (id);


--
-- Name: revenue_rules revenue_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.revenue_rules
    ADD CONSTRAINT revenue_rules_pkey PRIMARY KEY (id);


--
-- Name: revoked_tokens revoked_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.revoked_tokens
    ADD CONSTRAINT revoked_tokens_pkey PRIMARY KEY (id);


--
-- Name: risk_events risk_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_events
    ADD CONSTRAINT risk_events_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: room_revenue_logs room_revenue_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_revenue_logs
    ADD CONSTRAINT room_revenue_logs_pkey PRIMARY KEY (id);


--
-- Name: room_signals room_signals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_signals
    ADD CONSTRAINT room_signals_pkey PRIMARY KEY (id);


--
-- Name: room_themes room_themes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_themes
    ADD CONSTRAINT room_themes_pkey PRIMARY KEY (id);


--
-- Name: rtc_telemetry rtc_telemetry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rtc_telemetry
    ADD CONSTRAINT rtc_telemetry_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: share_events share_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_events
    ADD CONSTRAINT share_events_pkey PRIMARY KEY (id);


--
-- Name: short_video_comment_likes short_video_comment_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_comment_likes
    ADD CONSTRAINT short_video_comment_likes_pkey PRIMARY KEY (id);


--
-- Name: short_video_comments short_video_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_comments
    ADD CONSTRAINT short_video_comments_pkey PRIMARY KEY (id);


--
-- Name: short_video_hashtags short_video_hashtags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_hashtags
    ADD CONSTRAINT short_video_hashtags_pkey PRIMARY KEY (id);


--
-- Name: short_video_likes short_video_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_likes
    ADD CONSTRAINT short_video_likes_pkey PRIMARY KEY (id);


--
-- Name: short_video_mentions short_video_mentions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_mentions
    ADD CONSTRAINT short_video_mentions_pkey PRIMARY KEY (id);


--
-- Name: short_video_music short_video_music_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_music
    ADD CONSTRAINT short_video_music_pkey PRIMARY KEY (id);


--
-- Name: short_video_saves short_video_saves_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_saves
    ADD CONSTRAINT short_video_saves_pkey PRIMARY KEY (id);


--
-- Name: short_video_views short_video_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_views
    ADD CONSTRAINT short_video_views_pkey PRIMARY KEY (id);


--
-- Name: short_videos short_videos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_videos
    ADD CONSTRAINT short_videos_pkey PRIMARY KEY (id);


--
-- Name: site_announcements site_announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_announcements
    ADD CONSTRAINT site_announcements_pkey PRIMARY KEY (id);


--
-- Name: site_pages site_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_pages
    ADD CONSTRAINT site_pages_pkey PRIMARY KEY (id);


--
-- Name: site_presences site_presences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_presences
    ADD CONSTRAINT site_presences_pkey PRIMARY KEY (id);


--
-- Name: site_settings site_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_settings
    ADD CONSTRAINT site_settings_pkey PRIMARY KEY (id);


--
-- Name: site_visits site_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_visits
    ADD CONSTRAINT site_visits_pkey PRIMARY KEY (id);


--
-- Name: sms_delivery_logs sms_delivery_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sms_delivery_logs
    ADD CONSTRAINT sms_delivery_logs_pkey PRIMARY KEY (id);


--
-- Name: sms_provider_configs sms_provider_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sms_provider_configs
    ADD CONSTRAINT sms_provider_configs_pkey PRIMARY KEY (id);


--
-- Name: sms_provider_health sms_provider_health_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sms_provider_health
    ADD CONSTRAINT sms_provider_health_pkey PRIMARY KEY (id);


--
-- Name: sms_providers sms_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sms_providers
    ADD CONSTRAINT sms_providers_pkey PRIMARY KEY (id);


--
-- Name: social_actions social_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_actions
    ADD CONSTRAINT social_actions_pkey PRIMARY KEY (id);


--
-- Name: social_comments social_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_comments
    ADD CONSTRAINT social_comments_pkey PRIMARY KEY (id);


--
-- Name: social_likes social_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_likes
    ADD CONSTRAINT social_likes_pkey PRIMARY KEY (id);


--
-- Name: social_posts social_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_posts
    ADD CONSTRAINT social_posts_pkey PRIMARY KEY (id);


--
-- Name: sos_game_chats sos_game_chats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sos_game_chats
    ADD CONSTRAINT sos_game_chats_pkey PRIMARY KEY (id);


--
-- Name: sos_game_viewers sos_game_viewers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sos_game_viewers
    ADD CONSTRAINT sos_game_viewers_pkey PRIMARY KEY (id);


--
-- Name: sos_games sos_games_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sos_games
    ADD CONSTRAINT sos_games_pkey PRIMARY KEY (id);


--
-- Name: store_purchases store_purchases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.store_purchases
    ADD CONSTRAINT store_purchases_pkey PRIMARY KEY (id);


--
-- Name: stream_bans stream_bans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_bans
    ADD CONSTRAINT stream_bans_pkey PRIMARY KEY (id);


--
-- Name: stream_co_broadcasters stream_co_broadcasters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_co_broadcasters
    ADD CONSTRAINT stream_co_broadcasters_pkey PRIMARY KEY (id);


--
-- Name: stream_fortune_requests stream_fortune_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_fortune_requests
    ADD CONSTRAINT stream_fortune_requests_pkey PRIMARY KEY (id);


--
-- Name: stream_gifts stream_gifts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_gifts
    ADD CONSTRAINT stream_gifts_pkey PRIMARY KEY (id);


--
-- Name: stream_moderators stream_moderators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_moderators
    ADD CONSTRAINT stream_moderators_pkey PRIMARY KEY (id);


--
-- Name: stream_muted_viewers stream_muted_viewers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_muted_viewers
    ADD CONSTRAINT stream_muted_viewers_pkey PRIMARY KEY (id);


--
-- Name: support_messages support_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_messages
    ADD CONSTRAINT support_messages_pkey PRIMARY KEY (id);


--
-- Name: support_tickets support_tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_pkey PRIMARY KEY (id);


--
-- Name: supporter_levels supporter_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supporter_levels
    ADD CONSTRAINT supporter_levels_pkey PRIMARY KEY (id);


--
-- Name: team_members team_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_members
    ADD CONSTRAINT team_members_pkey PRIMARY KEY (id);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: teller_awards teller_awards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teller_awards
    ADD CONSTRAINT teller_awards_pkey PRIMARY KEY (id);


--
-- Name: teller_chat_messages teller_chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teller_chat_messages
    ADD CONSTRAINT teller_chat_messages_pkey PRIMARY KEY (id);


--
-- Name: teller_chat_sessions teller_chat_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teller_chat_sessions
    ADD CONSTRAINT teller_chat_sessions_pkey PRIMARY KEY (id);


--
-- Name: teller_gifts teller_gifts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teller_gifts
    ADD CONSTRAINT teller_gifts_pkey PRIMARY KEY (id);


--
-- Name: teller_warnings teller_warnings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teller_warnings
    ADD CONSTRAINT teller_warnings_pkey PRIMARY KEY (id);


--
-- Name: ticker_messages ticker_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticker_messages
    ADD CONSTRAINT ticker_messages_pkey PRIMARY KEY (id);


--
-- Name: tiktok_categories tiktok_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tiktok_categories
    ADD CONSTRAINT tiktok_categories_pkey PRIMARY KEY (id);


--
-- Name: tiktok_videos tiktok_videos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tiktok_videos
    ADD CONSTRAINT tiktok_videos_pkey PRIMARY KEY (id);


--
-- Name: topup_bonus_tiers topup_bonus_tiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topup_bonus_tiers
    ADD CONSTRAINT topup_bonus_tiers_pkey PRIMARY KEY (id);


--
-- Name: tournament_matches tournament_matches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournament_matches
    ADD CONSTRAINT tournament_matches_pkey PRIMARY KEY (id);


--
-- Name: tournament_rounds tournament_rounds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournament_rounds
    ADD CONSTRAINT tournament_rounds_pkey PRIMARY KEY (id);


--
-- Name: translations translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.translations
    ADD CONSTRAINT translations_pkey PRIMARY KEY (id);


--
-- Name: trend_video_categories trend_video_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trend_video_categories
    ADD CONSTRAINT trend_video_categories_pkey PRIMARY KEY (id);


--
-- Name: trend_videos trend_videos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trend_videos
    ADD CONSTRAINT trend_videos_pkey PRIMARY KEY (id);


--
-- Name: trending_topics trending_topics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trending_topics
    ADD CONSTRAINT trending_topics_pkey PRIMARY KEY (id);


--
-- Name: trtc_webhook_logs trtc_webhook_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trtc_webhook_logs
    ADD CONSTRAINT trtc_webhook_logs_pkey PRIMARY KEY (id);


--
-- Name: user_achievements user_achievements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_pkey PRIMARY KEY (id);


--
-- Name: user_blocks user_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT user_blocks_pkey PRIMARY KEY (id);


--
-- Name: user_daily_activity user_daily_activity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_daily_activity
    ADD CONSTRAINT user_daily_activity_pkey PRIMARY KEY (id);


--
-- Name: user_devices user_devices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_devices
    ADD CONSTRAINT user_devices_pkey PRIMARY KEY (id);


--
-- Name: user_fortune_streaks user_fortune_streaks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_fortune_streaks
    ADD CONSTRAINT user_fortune_streaks_pkey PRIMARY KEY (id);


--
-- Name: user_game_profiles user_game_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_game_profiles
    ADD CONSTRAINT user_game_profiles_pkey PRIMARY KEY (id);


--
-- Name: user_hourly_activity user_hourly_activity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_hourly_activity
    ADD CONSTRAINT user_hourly_activity_pkey PRIMARY KEY (id);


--
-- Name: user_login_sessions user_login_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_login_sessions
    ADD CONSTRAINT user_login_sessions_pkey PRIMARY KEY (id);


--
-- Name: user_mission_progress user_mission_progress_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_mission_progress
    ADD CONSTRAINT user_mission_progress_pkey PRIMARY KEY (id);


--
-- Name: user_online_events user_online_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_online_events
    ADD CONSTRAINT user_online_events_pkey PRIMARY KEY (id);


--
-- Name: user_permission_overrides user_permission_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_permission_overrides
    ADD CONSTRAINT user_permission_overrides_pkey PRIMARY KEY (id);


--
-- Name: user_reports user_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_reports
    ADD CONSTRAINT user_reports_pkey PRIMARY KEY (id);


--
-- Name: user_stories user_stories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_stories
    ADD CONSTRAINT user_stories_pkey PRIMARY KEY (id);


--
-- Name: user_timeline_events user_timeline_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_timeline_events
    ADD CONSTRAINT user_timeline_events_pkey PRIMARY KEY (id);


--
-- Name: user_token_revocations user_token_revocations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_token_revocations
    ADD CONSTRAINT user_token_revocations_pkey PRIMARY KEY ("userId");


--
-- Name: user_vip_preferences user_vip_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_vip_preferences
    ADD CONSTRAINT user_vip_preferences_pkey PRIMARY KEY (id);


--
-- Name: user_warnings user_warnings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_warnings
    ADD CONSTRAINT user_warnings_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: verifications verifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verifications
    ADD CONSTRAINT verifications_pkey PRIMARY KEY (id);


--
-- Name: video_stream_comments video_stream_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_stream_comments
    ADD CONSTRAINT video_stream_comments_pkey PRIMARY KEY (id);


--
-- Name: video_stream_likes video_stream_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_stream_likes
    ADD CONSTRAINT video_stream_likes_pkey PRIMARY KEY (id);


--
-- Name: video_stream_signals video_stream_signals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_stream_signals
    ADD CONSTRAINT video_stream_signals_pkey PRIMARY KEY (id);


--
-- Name: video_stream_viewers video_stream_viewers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_stream_viewers
    ADD CONSTRAINT video_stream_viewers_pkey PRIMARY KEY (id);


--
-- Name: video_streams video_streams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_streams
    ADD CONSTRAINT video_streams_pkey PRIMARY KEY (id);


--
-- Name: vip_xp_ledger vip_xp_ledger_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vip_xp_ledger
    ADD CONSTRAINT vip_xp_ledger_pkey PRIMARY KEY (id);


--
-- Name: voice_sessions voice_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voice_sessions
    ADD CONSTRAINT voice_sessions_pkey PRIMARY KEY (id);


--
-- Name: voice_signals voice_signals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voice_signals
    ADD CONSTRAINT voice_signals_pkey PRIMARY KEY (id);


--
-- Name: weekly_dream_reports weekly_dream_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weekly_dream_reports
    ADD CONSTRAINT weekly_dream_reports_pkey PRIMARY KEY (id);


--
-- Name: weekly_tournament_entries weekly_tournament_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weekly_tournament_entries
    ADD CONSTRAINT weekly_tournament_entries_pkey PRIMARY KEY (id);


--
-- Name: weekly_tournaments weekly_tournaments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weekly_tournaments
    ADD CONSTRAINT weekly_tournaments_pkey PRIMARY KEY (id);


--
-- Name: withdrawal_requests withdrawal_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdrawal_requests
    ADD CONSTRAINT withdrawal_requests_pkey PRIMARY KEY (id);


--
-- Name: account_deletions_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX account_deletions_status_idx ON public.account_deletions USING btree (status);


--
-- Name: account_deletions_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "account_deletions_userId_key" ON public.account_deletions USING btree ("userId");


--
-- Name: accounts_provider_providerAccountId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "accounts_provider_providerAccountId_key" ON public.accounts USING btree (provider, "providerAccountId");


--
-- Name: accounts_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "accounts_userId_idx" ON public.accounts USING btree ("userId");


--
-- Name: achievements_code_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX achievements_code_key ON public.achievements USING btree (code);


--
-- Name: ad_networks_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ad_networks_isActive_idx" ON public.ad_networks USING btree ("isActive");


--
-- Name: ad_networks_provider_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ad_networks_provider_key ON public.ad_networks USING btree (provider);


--
-- Name: ad_placements_adNetworkId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ad_placements_adNetworkId_idx" ON public.ad_placements USING btree ("adNetworkId");


--
-- Name: ad_placements_adType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ad_placements_adType_idx" ON public.ad_placements USING btree ("adType");


--
-- Name: ad_placements_isActive_sortOrder_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ad_placements_isActive_sortOrder_idx" ON public.ad_placements USING btree ("isActive", "sortOrder");


--
-- Name: ad_placements_placementKey_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "ad_placements_placementKey_key" ON public.ad_placements USING btree ("placementKey");


--
-- Name: admin_popups_isActive_lastSentAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "admin_popups_isActive_lastSentAt_idx" ON public.admin_popups USING btree ("isActive", "lastSentAt");


--
-- Name: admin_popups_isActive_priority_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "admin_popups_isActive_priority_idx" ON public.admin_popups USING btree ("isActive", priority);


--
-- Name: admin_user_actions_action_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_user_actions_action_idx ON public.admin_user_actions USING btree (action);


--
-- Name: admin_user_actions_adminId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "admin_user_actions_adminId_idx" ON public.admin_user_actions USING btree ("adminId");


--
-- Name: admin_user_actions_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "admin_user_actions_createdAt_idx" ON public.admin_user_actions USING btree ("createdAt");


--
-- Name: admin_user_actions_targetUserId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "admin_user_actions_targetUserId_idx" ON public.admin_user_actions USING btree ("targetUserId");


--
-- Name: agencies_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agencies_createdAt_idx" ON public.agencies USING btree ("createdAt");


--
-- Name: agencies_name_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX agencies_name_key ON public.agencies USING btree (name);


--
-- Name: agencies_ownerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agencies_ownerId_idx" ON public.agencies USING btree ("ownerId");


--
-- Name: agencies_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agencies_status_idx ON public.agencies USING btree (status);


--
-- Name: agency_bonus_rules_level_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX agency_bonus_rules_level_key ON public.agency_bonus_rules USING btree (level);


--
-- Name: agency_commission_rules_agencyId_sourceType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_commission_rules_agencyId_sourceType_idx" ON public.agency_commission_rules USING btree ("agencyId", "sourceType");


--
-- Name: agency_commission_rules_sourceType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_commission_rules_sourceType_idx" ON public.agency_commission_rules USING btree ("sourceType");


--
-- Name: agency_earnings_agencyId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_earnings_agencyId_createdAt_idx" ON public.agency_earnings USING btree ("agencyId", "createdAt");


--
-- Name: agency_earnings_agencyId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_earnings_agencyId_idx" ON public.agency_earnings USING btree ("agencyId");


--
-- Name: agency_earnings_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_earnings_createdAt_idx" ON public.agency_earnings USING btree ("createdAt");


--
-- Name: agency_earnings_sourceType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_earnings_sourceType_idx" ON public.agency_earnings USING btree ("sourceType");


--
-- Name: agency_earnings_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_earnings_userId_idx" ON public.agency_earnings USING btree ("userId");


--
-- Name: agency_leave_requests_agencyId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_leave_requests_agencyId_idx" ON public.agency_leave_requests USING btree ("agencyId");


--
-- Name: agency_leave_requests_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agency_leave_requests_status_idx ON public.agency_leave_requests USING btree (status);


--
-- Name: agency_leave_requests_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_leave_requests_userId_idx" ON public.agency_leave_requests USING btree ("userId");


--
-- Name: agency_penalties_agencyId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_penalties_agencyId_idx" ON public.agency_penalties USING btree ("agencyId");


--
-- Name: agency_penalties_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_penalties_isActive_idx" ON public.agency_penalties USING btree ("isActive");


--
-- Name: agency_tasks_agencyId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_tasks_agencyId_idx" ON public.agency_tasks USING btree ("agencyId");


--
-- Name: agency_tasks_agencyId_weekStart_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "agency_tasks_agencyId_weekStart_key" ON public.agency_tasks USING btree ("agencyId", "weekStart");


--
-- Name: agency_tasks_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agency_tasks_status_idx ON public.agency_tasks USING btree (status);


--
-- Name: agency_tasks_weekStart_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_tasks_weekStart_idx" ON public.agency_tasks USING btree ("weekStart");


--
-- Name: agency_users_agencyId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_users_agencyId_idx" ON public.agency_users USING btree ("agencyId");


--
-- Name: agency_users_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_users_isActive_idx" ON public.agency_users USING btree ("isActive");


--
-- Name: agency_users_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_users_userId_idx" ON public.agency_users USING btree ("userId");


--
-- Name: agency_users_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "agency_users_userId_key" ON public.agency_users USING btree ("userId");


--
-- Name: agency_wallet_transactions_agencyId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_wallet_transactions_agencyId_createdAt_idx" ON public.agency_wallet_transactions USING btree ("agencyId", "createdAt");


--
-- Name: agency_wallet_transactions_idempotencyKey_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_wallet_transactions_idempotencyKey_idx" ON public.agency_wallet_transactions USING btree ("idempotencyKey");


--
-- Name: agency_wallet_transactions_targetUserId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "agency_wallet_transactions_targetUserId_idx" ON public.agency_wallet_transactions USING btree ("targetUserId");


--
-- Name: agency_wallet_transactions_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agency_wallet_transactions_type_idx ON public.agency_wallet_transactions USING btree (type);


--
-- Name: agency_wallets_agencyId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "agency_wallets_agencyId_key" ON public.agency_wallets USING btree ("agencyId");


--
-- Name: animation_assignments_animationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "animation_assignments_animationId_idx" ON public.animation_assignments USING btree ("animationId");


--
-- Name: animation_assignments_endDate_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "animation_assignments_endDate_idx" ON public.animation_assignments USING btree ("endDate");


--
-- Name: animation_assignments_userId_category_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "animation_assignments_userId_category_isActive_idx" ON public.animation_assignments USING btree ("userId", category, "isActive");


--
-- Name: animation_assignments_userId_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "animation_assignments_userId_isActive_idx" ON public.animation_assignments USING btree ("userId", "isActive");


--
-- Name: animation_membership_defaults_animationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "animation_membership_defaults_animationId_idx" ON public.animation_membership_defaults USING btree ("animationId");


--
-- Name: animation_membership_defaults_membershipTier_category_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "animation_membership_defaults_membershipTier_category_key" ON public.animation_membership_defaults USING btree ("membershipTier", category);


--
-- Name: animation_playback_logs_animationId_playedAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "animation_playback_logs_animationId_playedAt_idx" ON public.animation_playback_logs USING btree ("animationId", "playedAt");


--
-- Name: animation_playback_logs_userId_playedAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "animation_playback_logs_userId_playedAt_idx" ON public.animation_playback_logs USING btree ("userId", "playedAt");


--
-- Name: animations_category_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX animations_category_status_idx ON public.animations USING btree (category, status);


--
-- Name: animations_legacyType_legacyRefId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "animations_legacyType_legacyRefId_idx" ON public.animations USING btree ("legacyType", "legacyRefId");


--
-- Name: animations_membershipLevel_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "animations_membershipLevel_idx" ON public.animations USING btree ("membershipLevel");


--
-- Name: animations_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX animations_slug_key ON public.animations USING btree (slug);


--
-- Name: animations_status_priority_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX animations_status_priority_idx ON public.animations USING btree (status, priority);


--
-- Name: anonymous_fortunes_anonymousUserId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "anonymous_fortunes_anonymousUserId_idx" ON public.anonymous_fortunes USING btree ("anonymousUserId");


--
-- Name: anonymous_users_deviceId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "anonymous_users_deviceId_key" ON public.anonymous_users USING btree ("deviceId");


--
-- Name: anonymous_users_username_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX anonymous_users_username_key ON public.anonymous_users USING btree (username);


--
-- Name: audit_logs_action_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_logs_action_idx ON public.audit_logs USING btree (action);


--
-- Name: audit_logs_actorId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "audit_logs_actorId_idx" ON public.audit_logs USING btree ("actorId");


--
-- Name: audit_logs_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "audit_logs_createdAt_idx" ON public.audit_logs USING btree ("createdAt");


--
-- Name: audit_logs_targetType_targetId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "audit_logs_targetType_targetId_idx" ON public.audit_logs USING btree ("targetType", "targetId");


--
-- Name: avatar_accessories_slot_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "avatar_accessories_slot_isActive_idx" ON public.avatar_accessories USING btree (slot, "isActive");


--
-- Name: avatar_accessories_tier_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "avatar_accessories_tier_isActive_idx" ON public.avatar_accessories USING btree (tier, "isActive");


--
-- Name: bana_ozel_history_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "bana_ozel_history_createdAt_idx" ON public.bana_ozel_history USING btree ("createdAt");


--
-- Name: bana_ozel_history_itemSlug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "bana_ozel_history_itemSlug_idx" ON public.bana_ozel_history USING btree ("itemSlug");


--
-- Name: bana_ozel_history_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "bana_ozel_history_userId_idx" ON public.bana_ozel_history USING btree ("userId");


--
-- Name: bana_ozel_items_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "bana_ozel_items_isActive_idx" ON public.bana_ozel_items USING btree ("isActive");


--
-- Name: bana_ozel_items_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bana_ozel_items_slug_key ON public.bana_ozel_items USING btree (slug);


--
-- Name: bana_ozel_items_sortOrder_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "bana_ozel_items_sortOrder_idx" ON public.bana_ozel_items USING btree ("sortOrder");


--
-- Name: blog_categories_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX blog_categories_slug_key ON public.blog_categories USING btree (slug);


--
-- Name: blog_comments_parentId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "blog_comments_parentId_idx" ON public.blog_comments USING btree ("parentId");


--
-- Name: blog_comments_postId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "blog_comments_postId_idx" ON public.blog_comments USING btree ("postId");


--
-- Name: blog_comments_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "blog_comments_userId_idx" ON public.blog_comments USING btree ("userId");


--
-- Name: blog_favorites_postId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "blog_favorites_postId_idx" ON public.blog_favorites USING btree ("postId");


--
-- Name: blog_favorites_postId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "blog_favorites_postId_userId_key" ON public.blog_favorites USING btree ("postId", "userId");


--
-- Name: blog_favorites_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "blog_favorites_userId_idx" ON public.blog_favorites USING btree ("userId");


--
-- Name: blog_likes_postId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "blog_likes_postId_idx" ON public.blog_likes USING btree ("postId");


--
-- Name: blog_likes_postId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "blog_likes_postId_userId_key" ON public.blog_likes USING btree ("postId", "userId");


--
-- Name: blog_posts_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX blog_posts_category_idx ON public.blog_posts USING btree (category);


--
-- Name: blog_posts_isFeatured_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "blog_posts_isFeatured_idx" ON public.blog_posts USING btree ("isFeatured");


--
-- Name: blog_posts_isPremium_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "blog_posts_isPremium_idx" ON public.blog_posts USING btree ("isPremium");


--
-- Name: blog_posts_isPublished_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "blog_posts_isPublished_idx" ON public.blog_posts USING btree ("isPublished");


--
-- Name: blog_posts_isTrending_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "blog_posts_isTrending_idx" ON public.blog_posts USING btree ("isTrending");


--
-- Name: blog_posts_publishedAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "blog_posts_publishedAt_idx" ON public.blog_posts USING btree ("publishedAt");


--
-- Name: blog_posts_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX blog_posts_slug_idx ON public.blog_posts USING btree (slug);


--
-- Name: blog_posts_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX blog_posts_slug_key ON public.blog_posts USING btree (slug);


--
-- Name: blog_posts_views_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX blog_posts_views_idx ON public.blog_posts USING btree (views);


--
-- Name: blog_posts_zodiacSign_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "blog_posts_zodiacSign_idx" ON public.blog_posts USING btree ("zodiacSign");


--
-- Name: bot_profiles_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "bot_profiles_isActive_idx" ON public.bot_profiles USING btree ("isActive");


--
-- Name: bot_profiles_personality_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bot_profiles_personality_idx ON public.bot_profiles USING btree (personality);


--
-- Name: bot_profiles_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "bot_profiles_userId_key" ON public.bot_profiles USING btree ("userId");


--
-- Name: broadcast_images_isActive_sortOrder_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "broadcast_images_isActive_sortOrder_idx" ON public.broadcast_images USING btree ("isActive", "sortOrder");


--
-- Name: celebrities_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX celebrities_category_idx ON public.celebrities USING btree (category);


--
-- Name: celebrities_followerCount_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "celebrities_followerCount_idx" ON public.celebrities USING btree ("followerCount");


--
-- Name: celebrities_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "celebrities_isActive_idx" ON public.celebrities USING btree ("isActive");


--
-- Name: celebrities_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX celebrities_slug_idx ON public.celebrities USING btree (slug);


--
-- Name: celebrities_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX celebrities_slug_key ON public.celebrities USING btree (slug);


--
-- Name: celebrity_follows_celebrityId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "celebrity_follows_celebrityId_idx" ON public.celebrity_follows USING btree ("celebrityId");


--
-- Name: celebrity_follows_userId_celebrityId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "celebrity_follows_userId_celebrityId_key" ON public.celebrity_follows USING btree ("userId", "celebrityId");


--
-- Name: celebrity_follows_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "celebrity_follows_userId_idx" ON public.celebrity_follows USING btree ("userId");


--
-- Name: celebrity_post_comments_postId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "celebrity_post_comments_postId_createdAt_idx" ON public.celebrity_post_comments USING btree ("postId", "createdAt");


--
-- Name: celebrity_post_comments_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "celebrity_post_comments_userId_idx" ON public.celebrity_post_comments USING btree ("userId");


--
-- Name: celebrity_post_likes_postId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "celebrity_post_likes_postId_idx" ON public.celebrity_post_likes USING btree ("postId");


--
-- Name: celebrity_post_likes_postId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "celebrity_post_likes_postId_userId_key" ON public.celebrity_post_likes USING btree ("postId", "userId");


--
-- Name: celebrity_post_likes_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "celebrity_post_likes_userId_idx" ON public.celebrity_post_likes USING btree ("userId");


--
-- Name: celebrity_posts_celebrityId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "celebrity_posts_celebrityId_createdAt_idx" ON public.celebrity_posts USING btree ("celebrityId", "createdAt");


--
-- Name: celebrity_posts_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "celebrity_posts_isActive_idx" ON public.celebrity_posts USING btree ("isActive");


--
-- Name: celebrity_posts_isPinned_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "celebrity_posts_isPinned_idx" ON public.celebrity_posts USING btree ("isPinned");


--
-- Name: celebrity_posts_platform_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX celebrity_posts_platform_idx ON public.celebrity_posts USING btree (platform);


--
-- Name: cfc_contests_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX cfc_contests_slug_key ON public.cfc_contests USING btree (slug);


--
-- Name: cfc_contests_startsAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "cfc_contests_startsAt_idx" ON public.cfc_contests USING btree ("startsAt");


--
-- Name: cfc_contests_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cfc_contests_status_idx ON public.cfc_contests USING btree (status);


--
-- Name: cfc_contests_type_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cfc_contests_type_status_idx ON public.cfc_contests USING btree (type, status);


--
-- Name: cfc_participants_contestId_rank_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "cfc_participants_contestId_rank_idx" ON public.cfc_participants USING btree ("contestId", rank);


--
-- Name: cfc_participants_contestId_score_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "cfc_participants_contestId_score_idx" ON public.cfc_participants USING btree ("contestId", score);


--
-- Name: cfc_participants_contestId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "cfc_participants_contestId_userId_key" ON public.cfc_participants USING btree ("contestId", "userId");


--
-- Name: cfc_payment_requests_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "cfc_payment_requests_createdAt_idx" ON public.cfc_payment_requests USING btree ("createdAt");


--
-- Name: cfc_payment_requests_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cfc_payment_requests_status_idx ON public.cfc_payment_requests USING btree (status);


--
-- Name: cfc_payment_requests_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "cfc_payment_requests_userId_idx" ON public.cfc_payment_requests USING btree ("userId");


--
-- Name: cfc_score_logs_contestId_calculatedAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "cfc_score_logs_contestId_calculatedAt_idx" ON public.cfc_score_logs USING btree ("contestId", "calculatedAt");


--
-- Name: cfc_score_logs_contestId_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "cfc_score_logs_contestId_userId_idx" ON public.cfc_score_logs USING btree ("contestId", "userId");


--
-- Name: cfc_seasons_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX cfc_seasons_slug_key ON public.cfc_seasons USING btree (slug);


--
-- Name: cfc_teams_contestId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "cfc_teams_contestId_idx" ON public.cfc_teams USING btree ("contestId");


--
-- Name: chat_bans_roomId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_bans_roomId_idx" ON public.chat_bans USING btree ("roomId");


--
-- Name: chat_bans_roomId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "chat_bans_roomId_userId_key" ON public.chat_bans USING btree ("roomId", "userId");


--
-- Name: chat_bubble_skins_tier_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_bubble_skins_tier_isActive_idx" ON public.chat_bubble_skins USING btree (tier, "isActive");


--
-- Name: chat_messages_roomId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_messages_roomId_createdAt_idx" ON public.chat_messages USING btree ("roomId", "createdAt");


--
-- Name: chat_messages_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_messages_userId_idx" ON public.chat_messages USING btree ("userId");


--
-- Name: chat_mutes_roomId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_mutes_roomId_idx" ON public.chat_mutes USING btree ("roomId");


--
-- Name: chat_mutes_roomId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "chat_mutes_roomId_userId_key" ON public.chat_mutes USING btree ("roomId", "userId");


--
-- Name: chat_presences_lastSeen_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_presences_lastSeen_idx" ON public.chat_presences USING btree ("lastSeen");


--
-- Name: chat_presences_roomId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_presences_roomId_idx" ON public.chat_presences USING btree ("roomId");


--
-- Name: chat_presences_roomId_lastSeen_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_presences_roomId_lastSeen_idx" ON public.chat_presences USING btree ("roomId", "lastSeen");


--
-- Name: chat_presences_roomId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "chat_presences_roomId_userId_key" ON public.chat_presences USING btree ("roomId", "userId");


--
-- Name: chat_presences_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_presences_userId_idx" ON public.chat_presences USING btree ("userId");


--
-- Name: chat_room_gifts_recipientId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_room_gifts_recipientId_idx" ON public.chat_room_gifts USING btree ("recipientId");


--
-- Name: chat_room_gifts_roomId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_room_gifts_roomId_createdAt_idx" ON public.chat_room_gifts USING btree ("roomId", "createdAt" DESC);


--
-- Name: chat_room_gifts_roomId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_room_gifts_roomId_idx" ON public.chat_room_gifts USING btree ("roomId");


--
-- Name: chat_room_gifts_roomId_senderId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_room_gifts_roomId_senderId_idx" ON public.chat_room_gifts USING btree ("roomId", "senderId");


--
-- Name: chat_room_gifts_senderId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_room_gifts_senderId_idx" ON public.chat_room_gifts USING btree ("senderId");


--
-- Name: chat_rooms_isActive_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_rooms_isActive_createdAt_idx" ON public.chat_rooms USING btree ("isActive", "createdAt");


--
-- Name: chat_rooms_ownerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_rooms_ownerId_idx" ON public.chat_rooms USING btree ("ownerId");


--
-- Name: chat_rooms_roomType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_rooms_roomType_idx" ON public.chat_rooms USING btree ("roomType");


--
-- Name: chat_rooms_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX chat_rooms_slug_key ON public.chat_rooms USING btree (slug);


--
-- Name: chat_speak_blocks_roomId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_speak_blocks_roomId_idx" ON public.chat_speak_blocks USING btree ("roomId");


--
-- Name: chat_speak_blocks_roomId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "chat_speak_blocks_roomId_userId_key" ON public.chat_speak_blocks USING btree ("roomId", "userId");


--
-- Name: chat_speak_requests_roomId_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_speak_requests_roomId_status_idx" ON public.chat_speak_requests USING btree ("roomId", status);


--
-- Name: chat_speak_requests_roomId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "chat_speak_requests_roomId_userId_key" ON public.chat_speak_requests USING btree ("roomId", "userId");


--
-- Name: chat_speak_requests_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_speak_requests_userId_idx" ON public.chat_speak_requests USING btree ("userId");


--
-- Name: chat_user_roles_roomId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_user_roles_roomId_idx" ON public.chat_user_roles USING btree ("roomId");


--
-- Name: chat_user_roles_roomId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "chat_user_roles_roomId_userId_key" ON public.chat_user_roles USING btree ("roomId", "userId");


--
-- Name: chat_user_roles_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_user_roles_userId_idx" ON public.chat_user_roles USING btree ("userId");


--
-- Name: conversations_lastMessageAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "conversations_lastMessageAt_idx" ON public.conversations USING btree ("lastMessageAt");


--
-- Name: conversations_user1Id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "conversations_user1Id_idx" ON public.conversations USING btree ("user1Id");


--
-- Name: conversations_user1Id_user2Id_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "conversations_user1Id_user2Id_key" ON public.conversations USING btree ("user1Id", "user2Id");


--
-- Name: conversations_user2Id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "conversations_user2Id_idx" ON public.conversations USING btree ("user2Id");


--
-- Name: credit_transactions_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "credit_transactions_createdAt_idx" ON public.credit_transactions USING btree ("createdAt");


--
-- Name: credit_transactions_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_transactions_type_idx ON public.credit_transactions USING btree (type);


--
-- Name: credit_transactions_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "credit_transactions_userId_idx" ON public.credit_transactions USING btree ("userId");


--
-- Name: currency_config_area_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX currency_config_area_key ON public.currency_config USING btree (area);


--
-- Name: currency_config_currencyType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "currency_config_currencyType_idx" ON public.currency_config USING btree ("currencyType");


--
-- Name: custom_badges_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "custom_badges_isActive_idx" ON public.custom_badges USING btree ("isActive");


--
-- Name: custom_badges_tier_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX custom_badges_tier_idx ON public.custom_badges USING btree (tier);


--
-- Name: custom_badges_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "custom_badges_userId_idx" ON public.custom_badges USING btree ("userId");


--
-- Name: daily_login_rewards_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "daily_login_rewards_userId_idx" ON public.daily_login_rewards USING btree ("userId");


--
-- Name: daily_login_rewards_userId_rewardDate_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "daily_login_rewards_userId_rewardDate_key" ON public.daily_login_rewards USING btree ("userId", "rewardDate");


--
-- Name: daily_quests_questDate_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "daily_quests_questDate_idx" ON public.daily_quests USING btree ("questDate");


--
-- Name: daily_quests_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "daily_quests_userId_idx" ON public.daily_quests USING btree ("userId");


--
-- Name: daily_quests_userId_questDate_questType_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "daily_quests_userId_questDate_questType_key" ON public.daily_quests USING btree ("userId", "questDate", "questType");


--
-- Name: daily_rewards_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "daily_rewards_userId_idx" ON public.daily_rewards USING btree ("userId");


--
-- Name: daily_rewards_userId_rewardDate_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "daily_rewards_userId_rewardDate_key" ON public.daily_rewards USING btree ("userId", "rewardDate");


--
-- Name: daily_tasks_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX daily_tasks_date_idx ON public.daily_tasks USING btree (date);


--
-- Name: daily_tasks_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "daily_tasks_userId_idx" ON public.daily_tasks USING btree ("userId");


--
-- Name: daily_tasks_userId_taskType_date_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "daily_tasks_userId_taskType_date_key" ON public.daily_tasks USING btree ("userId", "taskType", date);


--
-- Name: direct_messages_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "direct_messages_createdAt_idx" ON public.direct_messages USING btree ("createdAt");


--
-- Name: direct_messages_receiverId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "direct_messages_receiverId_idx" ON public.direct_messages USING btree ("receiverId");


--
-- Name: direct_messages_receiverId_isRead_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "direct_messages_receiverId_isRead_idx" ON public.direct_messages USING btree ("receiverId", "isRead");


--
-- Name: direct_messages_receiverId_senderId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "direct_messages_receiverId_senderId_createdAt_idx" ON public.direct_messages USING btree ("receiverId", "senderId", "createdAt" DESC);


--
-- Name: direct_messages_senderId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "direct_messages_senderId_idx" ON public.direct_messages USING btree ("senderId");


--
-- Name: direct_messages_senderId_receiverId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "direct_messages_senderId_receiverId_createdAt_idx" ON public.direct_messages USING btree ("senderId", "receiverId", "createdAt" DESC);


--
-- Name: dream_comments_dreamId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "dream_comments_dreamId_createdAt_idx" ON public.dream_comments USING btree ("dreamId", "createdAt");


--
-- Name: dream_comments_experienceType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "dream_comments_experienceType_idx" ON public.dream_comments USING btree ("experienceType");


--
-- Name: dream_comments_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "dream_comments_userId_idx" ON public.dream_comments USING btree ("userId");


--
-- Name: dream_contest_entries_contestId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "dream_contest_entries_contestId_userId_key" ON public.dream_contest_entries USING btree ("contestId", "userId");


--
-- Name: dream_contest_entries_contestId_voteCount_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "dream_contest_entries_contestId_voteCount_idx" ON public.dream_contest_entries USING btree ("contestId", "voteCount");


--
-- Name: dream_contest_entries_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "dream_contest_entries_userId_idx" ON public.dream_contest_entries USING btree ("userId");


--
-- Name: dream_contest_votes_entryId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "dream_contest_votes_entryId_idx" ON public.dream_contest_votes USING btree ("entryId");


--
-- Name: dream_contest_votes_entryId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "dream_contest_votes_entryId_userId_key" ON public.dream_contest_votes USING btree ("entryId", "userId");


--
-- Name: dream_contest_votes_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "dream_contest_votes_userId_idx" ON public.dream_contest_votes USING btree ("userId");


--
-- Name: dream_contests_endDate_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "dream_contests_endDate_idx" ON public.dream_contests USING btree ("endDate");


--
-- Name: dream_contests_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "dream_contests_isActive_idx" ON public.dream_contests USING btree ("isActive");


--
-- Name: dream_diary_entries_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "dream_diary_entries_createdAt_idx" ON public.dream_diary_entries USING btree ("createdAt");


--
-- Name: dream_diary_entries_userId_dreamDate_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "dream_diary_entries_userId_dreamDate_idx" ON public.dream_diary_entries USING btree ("userId", "dreamDate");


--
-- Name: dream_diary_entries_userId_dreamDate_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "dream_diary_entries_userId_dreamDate_key" ON public.dream_diary_entries USING btree ("userId", "dreamDate");


--
-- Name: dream_favorites_dreamId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "dream_favorites_dreamId_idx" ON public.dream_favorites USING btree ("dreamId");


--
-- Name: dream_favorites_userId_dreamId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "dream_favorites_userId_dreamId_key" ON public.dream_favorites USING btree ("userId", "dreamId");


--
-- Name: dream_favorites_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "dream_favorites_userId_idx" ON public.dream_favorites USING btree ("userId");


--
-- Name: dream_interpretations_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX dream_interpretations_category_idx ON public.dream_interpretations USING btree (category);


--
-- Name: dream_interpretations_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "dream_interpretations_createdAt_idx" ON public.dream_interpretations USING btree ("createdAt");


--
-- Name: dream_interpretations_isPublished_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "dream_interpretations_isPublished_idx" ON public.dream_interpretations USING btree ("isPublished");


--
-- Name: dream_interpretations_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX dream_interpretations_slug_idx ON public.dream_interpretations USING btree (slug);


--
-- Name: dream_interpretations_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX dream_interpretations_slug_key ON public.dream_interpretations USING btree (slug);


--
-- Name: dream_interpretations_views_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX dream_interpretations_views_idx ON public.dream_interpretations USING btree (views);


--
-- Name: dream_symbols_isPublished_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "dream_symbols_isPublished_idx" ON public.dream_symbols USING btree ("isPublished");


--
-- Name: dream_symbols_letter_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX dream_symbols_letter_idx ON public.dream_symbols USING btree (letter);


--
-- Name: dream_symbols_name_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX dream_symbols_name_key ON public.dream_symbols USING btree (name);


--
-- Name: dream_symbols_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX dream_symbols_slug_idx ON public.dream_symbols USING btree (slug);


--
-- Name: dream_symbols_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX dream_symbols_slug_key ON public.dream_symbols USING btree (slug);


--
-- Name: dream_views_dreamId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "dream_views_dreamId_idx" ON public.dream_views USING btree ("dreamId");


--
-- Name: dream_views_userId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "dream_views_userId_createdAt_idx" ON public.dream_views USING btree ("userId", "createdAt");


--
-- Name: effect_rules_conditionType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "effect_rules_conditionType_idx" ON public.effect_rules USING btree ("conditionType");


--
-- Name: effect_rules_effectType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "effect_rules_effectType_idx" ON public.effect_rules USING btree ("effectType");


--
-- Name: effect_rules_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "effect_rules_isActive_idx" ON public.effect_rules USING btree ("isActive");


--
-- Name: effect_rules_key_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX effect_rules_key_key ON public.effect_rules USING btree (key);


--
-- Name: email_verification_tokens_token_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX email_verification_tokens_token_idx ON public.email_verification_tokens USING btree (token);


--
-- Name: email_verification_tokens_token_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX email_verification_tokens_token_key ON public.email_verification_tokens USING btree (token);


--
-- Name: email_verification_tokens_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "email_verification_tokens_userId_idx" ON public.email_verification_tokens USING btree ("userId");


--
-- Name: emoji_packs_tier_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "emoji_packs_tier_isActive_idx" ON public.emoji_packs USING btree (tier, "isActive");


--
-- Name: entrance_effects_tier_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "entrance_effects_tier_isActive_idx" ON public.entrance_effects USING btree (tier, "isActive");


--
-- Name: fan_club_members_fanClubId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "fan_club_members_fanClubId_idx" ON public.fan_club_members USING btree ("fanClubId");


--
-- Name: fan_club_members_fanClubId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "fan_club_members_fanClubId_userId_key" ON public.fan_club_members USING btree ("fanClubId", "userId");


--
-- Name: fan_club_members_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "fan_club_members_userId_idx" ON public.fan_club_members USING btree ("userId");


--
-- Name: fan_club_poll_votes_pollId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "fan_club_poll_votes_pollId_idx" ON public.fan_club_poll_votes USING btree ("pollId");


--
-- Name: fan_club_poll_votes_pollId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "fan_club_poll_votes_pollId_userId_key" ON public.fan_club_poll_votes USING btree ("pollId", "userId");


--
-- Name: fan_club_poll_votes_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "fan_club_poll_votes_userId_idx" ON public.fan_club_poll_votes USING btree ("userId");


--
-- Name: fan_club_polls_fanClubId_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "fan_club_polls_fanClubId_isActive_idx" ON public.fan_club_polls USING btree ("fanClubId", "isActive");


--
-- Name: fan_club_polls_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "fan_club_polls_userId_idx" ON public.fan_club_polls USING btree ("userId");


--
-- Name: fan_club_post_likes_postId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "fan_club_post_likes_postId_idx" ON public.fan_club_post_likes USING btree ("postId");


--
-- Name: fan_club_post_likes_postId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "fan_club_post_likes_postId_userId_key" ON public.fan_club_post_likes USING btree ("postId", "userId");


--
-- Name: fan_club_post_likes_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "fan_club_post_likes_userId_idx" ON public.fan_club_post_likes USING btree ("userId");


--
-- Name: fan_club_posts_fanClubId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "fan_club_posts_fanClubId_createdAt_idx" ON public.fan_club_posts USING btree ("fanClubId", "createdAt");


--
-- Name: fan_club_posts_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "fan_club_posts_userId_idx" ON public.fan_club_posts USING btree ("userId");


--
-- Name: fan_clubs_celebrityId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "fan_clubs_celebrityId_key" ON public.fan_clubs USING btree ("celebrityId");


--
-- Name: fan_clubs_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "fan_clubs_isActive_idx" ON public.fan_clubs USING btree ("isActive");


--
-- Name: favorite_tellers_tellerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "favorite_tellers_tellerId_idx" ON public.favorite_tellers USING btree ("tellerId");


--
-- Name: favorite_tellers_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "favorite_tellers_userId_idx" ON public.favorite_tellers USING btree ("userId");


--
-- Name: favorite_tellers_userId_tellerId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "favorite_tellers_userId_tellerId_key" ON public.favorite_tellers USING btree ("userId", "tellerId");


--
-- Name: feature_flags_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX feature_flags_key_idx ON public.feature_flags USING btree (key);


--
-- Name: feature_flags_key_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX feature_flags_key_key ON public.feature_flags USING btree (key);


--
-- Name: follows_followerId_followingId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "follows_followerId_followingId_key" ON public.follows USING btree ("followerId", "followingId");


--
-- Name: follows_followerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "follows_followerId_idx" ON public.follows USING btree ("followerId");


--
-- Name: follows_followingId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "follows_followingId_idx" ON public.follows USING btree ("followingId");


--
-- Name: fortune_ratings_fortuneId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "fortune_ratings_fortuneId_idx" ON public.fortune_ratings USING btree ("fortuneId");


--
-- Name: fortune_ratings_fortuneId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "fortune_ratings_fortuneId_key" ON public.fortune_ratings USING btree ("fortuneId");


--
-- Name: fortune_ratings_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "fortune_ratings_userId_idx" ON public.fortune_ratings USING btree ("userId");


--
-- Name: fortunes_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "fortunes_createdAt_idx" ON public.fortunes USING btree ("createdAt");


--
-- Name: fortunes_fortuneType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "fortunes_fortuneType_idx" ON public.fortunes USING btree ("fortuneType");


--
-- Name: fortunes_isPinned_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "fortunes_isPinned_idx" ON public.fortunes USING btree ("isPinned");


--
-- Name: fortunes_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "fortunes_userId_idx" ON public.fortunes USING btree ("userId");


--
-- Name: game_plays_gameId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "game_plays_gameId_idx" ON public.game_plays USING btree ("gameId");


--
-- Name: game_plays_playedAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "game_plays_playedAt_idx" ON public.game_plays USING btree ("playedAt");


--
-- Name: game_plays_userId_gameId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "game_plays_userId_gameId_idx" ON public.game_plays USING btree ("userId", "gameId");


--
-- Name: game_plays_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "game_plays_userId_idx" ON public.game_plays USING btree ("userId");


--
-- Name: game_room_chats_roomId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "game_room_chats_roomId_createdAt_idx" ON public.game_room_chats USING btree ("roomId", "createdAt");


--
-- Name: game_room_viewers_roomId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "game_room_viewers_roomId_idx" ON public.game_room_viewers USING btree ("roomId");


--
-- Name: game_room_viewers_roomId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "game_room_viewers_roomId_userId_key" ON public.game_room_viewers USING btree ("roomId", "userId");


--
-- Name: game_rooms_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "game_rooms_createdAt_idx" ON public.game_rooms USING btree ("createdAt");


--
-- Name: game_rooms_gameType_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "game_rooms_gameType_status_idx" ON public.game_rooms USING btree ("gameType", status);


--
-- Name: game_rooms_player1Id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "game_rooms_player1Id_idx" ON public.game_rooms USING btree ("player1Id");


--
-- Name: game_rooms_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX game_rooms_status_idx ON public.game_rooms USING btree (status);


--
-- Name: gift_battle_participants_battleId_participantId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "gift_battle_participants_battleId_participantId_key" ON public.gift_battle_participants USING btree ("battleId", "participantId");


--
-- Name: gift_battle_participants_battleId_score_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_battle_participants_battleId_score_idx" ON public.gift_battle_participants USING btree ("battleId", score);


--
-- Name: gift_battles_context_contextId_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_battles_context_contextId_status_idx" ON public.gift_battles USING btree (context, "contextId", status);


--
-- Name: gift_battles_status_endsAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_battles_status_endsAt_idx" ON public.gift_battles USING btree (status, "endsAt");


--
-- Name: gift_box_entries_boxId_isWinner_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_box_entries_boxId_isWinner_idx" ON public.gift_box_entries USING btree ("boxId", "isWinner");


--
-- Name: gift_box_entries_boxId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "gift_box_entries_boxId_userId_key" ON public.gift_box_entries USING btree ("boxId", "userId");


--
-- Name: gift_box_entries_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_box_entries_userId_idx" ON public.gift_box_entries USING btree ("userId");


--
-- Name: gift_boxes_creatorId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_boxes_creatorId_idx" ON public.gift_boxes USING btree ("creatorId");


--
-- Name: gift_boxes_roomId_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_boxes_roomId_status_idx" ON public.gift_boxes USING btree ("roomId", status);


--
-- Name: gift_boxes_status_endsAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_boxes_status_endsAt_idx" ON public.gift_boxes USING btree (status, "endsAt");


--
-- Name: gift_boxes_streamId_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_boxes_streamId_status_idx" ON public.gift_boxes USING btree ("streamId", status);


--
-- Name: gift_collections_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX gift_collections_slug_key ON public.gift_collections USING btree (slug);


--
-- Name: gift_combos_contextId_senderId_giftTypeId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "gift_combos_contextId_senderId_giftTypeId_key" ON public.gift_combos USING btree ("contextId", "senderId", "giftTypeId");


--
-- Name: gift_combos_contextId_senderId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_combos_contextId_senderId_idx" ON public.gift_combos USING btree ("contextId", "senderId");


--
-- Name: gift_combos_expiresAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_combos_expiresAt_idx" ON public.gift_combos USING btree ("expiresAt");


--
-- Name: gift_events_battleId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_events_battleId_idx" ON public.gift_events USING btree ("battleId");


--
-- Name: gift_events_context_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_events_context_createdAt_idx" ON public.gift_events USING btree (context, "createdAt");


--
-- Name: gift_events_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_events_createdAt_idx" ON public.gift_events USING btree ("createdAt");


--
-- Name: gift_events_giftTypeId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_events_giftTypeId_idx" ON public.gift_events USING btree ("giftTypeId");


--
-- Name: gift_events_idempotencyKey_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "gift_events_idempotencyKey_key" ON public.gift_events USING btree ("idempotencyKey");


--
-- Name: gift_events_receiverId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_events_receiverId_createdAt_idx" ON public.gift_events USING btree ("receiverId", "createdAt");


--
-- Name: gift_events_senderId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_events_senderId_createdAt_idx" ON public.gift_events USING btree ("senderId", "createdAt");


--
-- Name: gift_goals_context_contextId_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_goals_context_contextId_status_idx" ON public.gift_goals USING btree (context, "contextId", status);


--
-- Name: gift_history_contextId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_history_contextId_createdAt_idx" ON public.gift_history USING btree ("contextId", "createdAt");


--
-- Name: gift_history_giftTypeId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_history_giftTypeId_createdAt_idx" ON public.gift_history USING btree ("giftTypeId", "createdAt");


--
-- Name: gift_history_receiverId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_history_receiverId_createdAt_idx" ON public.gift_history USING btree ("receiverId", "createdAt");


--
-- Name: gift_history_senderId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_history_senderId_createdAt_idx" ON public.gift_history USING btree ("senderId", "createdAt");


--
-- Name: gift_missions_code_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX gift_missions_code_key ON public.gift_missions USING btree (code);


--
-- Name: gift_queue_contextId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_queue_contextId_createdAt_idx" ON public.gift_queue USING btree ("contextId", "createdAt");


--
-- Name: gift_queue_contextId_status_queueIndex_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_queue_contextId_status_queueIndex_idx" ON public.gift_queue USING btree ("contextId", status, "queueIndex");


--
-- Name: gift_queue_status_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_queue_status_createdAt_idx" ON public.gift_queue USING btree (status, "createdAt");


--
-- Name: gift_types_collectionId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_types_collectionId_idx" ON public.gift_types USING btree ("collectionId");


--
-- Name: gift_types_contentVersion_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_types_contentVersion_idx" ON public.gift_types USING btree ("contentVersion");


--
-- Name: gift_types_displayType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "gift_types_displayType_idx" ON public.gift_types USING btree ("displayType");


--
-- Name: gift_types_priority_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gift_types_priority_idx ON public.gift_types USING btree (priority);


--
-- Name: hashtags_name_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX hashtags_name_key ON public.hashtags USING btree (name);


--
-- Name: hashtags_videosCount_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hashtags_videosCount_idx" ON public.hashtags USING btree ("videosCount" DESC);


--
-- Name: homepage_buttons_key_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX homepage_buttons_key_key ON public.homepage_buttons USING btree (key);


--
-- Name: homepage_buttons_sortOrder_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "homepage_buttons_sortOrder_idx" ON public.homepage_buttons USING btree ("sortOrder");


--
-- Name: homepage_fortune_cards_isActive_sortOrder_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "homepage_fortune_cards_isActive_sortOrder_idx" ON public.homepage_fortune_cards USING btree ("isActive", "sortOrder");


--
-- Name: idempotency_records_expiresAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "idempotency_records_expiresAt_idx" ON public.idempotency_records USING btree ("expiresAt");


--
-- Name: idempotency_records_key_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idempotency_records_key_key ON public.idempotency_records USING btree (key);


--
-- Name: idempotency_records_scope_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idempotency_records_scope_idx ON public.idempotency_records USING btree (scope);


--
-- Name: idempotency_records_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "idempotency_records_userId_idx" ON public.idempotency_records USING btree ("userId");


--
-- Name: integration_secrets_scope_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX integration_secrets_scope_idx ON public.integration_secrets USING btree (scope);


--
-- Name: integration_secrets_scope_providerKey_fieldKey_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "integration_secrets_scope_providerKey_fieldKey_key" ON public.integration_secrets USING btree (scope, "providerKey", "fieldKey");


--
-- Name: integration_settings_key_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX integration_settings_key_key ON public.integration_settings USING btree (key);


--
-- Name: invite_codes_agencyId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "invite_codes_agencyId_idx" ON public.invite_codes USING btree ("agencyId");


--
-- Name: invite_codes_code_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invite_codes_code_idx ON public.invite_codes USING btree (code);


--
-- Name: invite_codes_code_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX invite_codes_code_key ON public.invite_codes USING btree (code);


--
-- Name: ip_fortune_usage_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ip_fortune_usage_date_idx ON public.ip_fortune_usage USING btree (date);


--
-- Name: ip_fortune_usage_ipAddress_date_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "ip_fortune_usage_ipAddress_date_key" ON public.ip_fortune_usage USING btree ("ipAddress", date);


--
-- Name: ip_fortune_usage_ipAddress_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ip_fortune_usage_ipAddress_idx" ON public.ip_fortune_usage USING btree ("ipAddress");


--
-- Name: jeton_transactions_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "jeton_transactions_createdAt_idx" ON public.jeton_transactions USING btree ("createdAt");


--
-- Name: jeton_transactions_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX jeton_transactions_type_idx ON public.jeton_transactions USING btree (type);


--
-- Name: jeton_transactions_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "jeton_transactions_userId_idx" ON public.jeton_transactions USING btree ("userId");


--
-- Name: leaderboard_configs_scope_periodType_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "leaderboard_configs_scope_periodType_key" ON public.leaderboard_configs USING btree (scope, "periodType");


--
-- Name: leaderboard_entries_periodId_score_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "leaderboard_entries_periodId_score_idx" ON public.leaderboard_entries USING btree ("periodId", score);


--
-- Name: leaderboard_entries_periodId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "leaderboard_entries_periodId_userId_key" ON public.leaderboard_entries USING btree ("periodId", "userId");


--
-- Name: leaderboard_entries_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "leaderboard_entries_userId_idx" ON public.leaderboard_entries USING btree ("userId");


--
-- Name: leaderboard_periods_configId_periodKey_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "leaderboard_periods_configId_periodKey_key" ON public.leaderboard_periods USING btree ("configId", "periodKey");


--
-- Name: leaderboard_periods_endTime_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "leaderboard_periods_endTime_status_idx" ON public.leaderboard_periods USING btree ("endTime", status);


--
-- Name: leaderboard_periods_scope_periodType_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "leaderboard_periods_scope_periodType_status_idx" ON public.leaderboard_periods USING btree (scope, "periodType", status);


--
-- Name: leaderboard_rewards_periodId_rank_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "leaderboard_rewards_periodId_rank_key" ON public.leaderboard_rewards USING btree ("periodId", rank);


--
-- Name: leaderboard_rewards_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "leaderboard_rewards_userId_idx" ON public.leaderboard_rewards USING btree ("userId");


--
-- Name: ledger_entries_accountId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ledger_entries_accountId_createdAt_idx" ON public.ledger_entries USING btree ("accountId", "createdAt");


--
-- Name: ledger_entries_accountType_accountId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ledger_entries_accountType_accountId_idx" ON public.ledger_entries USING btree ("accountType", "accountId");


--
-- Name: ledger_entries_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ledger_entries_category_idx ON public.ledger_entries USING btree (category);


--
-- Name: ledger_entries_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ledger_entries_createdAt_idx" ON public.ledger_entries USING btree ("createdAt");


--
-- Name: ledger_entries_referenceType_referenceId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ledger_entries_referenceType_referenceId_idx" ON public.ledger_entries USING btree ("referenceType", "referenceId");


--
-- Name: ledger_entries_transactionId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ledger_entries_transactionId_idx" ON public.ledger_entries USING btree ("transactionId");


--
-- Name: live_activities_activityType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_activities_activityType_idx" ON public.live_activities USING btree ("activityType");


--
-- Name: live_activities_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_activities_createdAt_idx" ON public.live_activities USING btree ("createdAt");


--
-- Name: live_fortune_tellers_applicationStatus_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_fortune_tellers_applicationStatus_idx" ON public.live_fortune_tellers USING btree ("applicationStatus");


--
-- Name: live_fortune_tellers_isBanned_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_fortune_tellers_isBanned_idx" ON public.live_fortune_tellers USING btree ("isBanned");


--
-- Name: live_fortune_tellers_isOnline_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_fortune_tellers_isOnline_idx" ON public.live_fortune_tellers USING btree ("isOnline");


--
-- Name: live_fortune_tellers_isOnline_rating_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_fortune_tellers_isOnline_rating_idx" ON public.live_fortune_tellers USING btree ("isOnline", rating DESC);


--
-- Name: live_fortune_tellers_isVerified_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_fortune_tellers_isVerified_idx" ON public.live_fortune_tellers USING btree ("isVerified");


--
-- Name: live_fortune_tellers_rating_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX live_fortune_tellers_rating_idx ON public.live_fortune_tellers USING btree (rating);


--
-- Name: live_fortune_tellers_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "live_fortune_tellers_userId_key" ON public.live_fortune_tellers USING btree ("userId");


--
-- Name: live_fortune_tellers_verificationStatus_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_fortune_tellers_verificationStatus_idx" ON public.live_fortune_tellers USING btree ("verificationStatus");


--
-- Name: live_guest_invites_guestId_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_guest_invites_guestId_status_idx" ON public.live_guest_invites USING btree ("guestId", status);


--
-- Name: live_guest_invites_status_expiresAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_guest_invites_status_expiresAt_idx" ON public.live_guest_invites USING btree (status, "expiresAt");


--
-- Name: live_guest_invites_streamId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_guest_invites_streamId_idx" ON public.live_guest_invites USING btree ("streamId");


--
-- Name: live_guest_invites_streamId_kind_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_guest_invites_streamId_kind_status_idx" ON public.live_guest_invites USING btree ("streamId", kind, status);


--
-- Name: live_guest_sessions_streamId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_guest_sessions_streamId_idx" ON public.live_guest_sessions USING btree ("streamId");


--
-- Name: live_guest_sessions_streamId_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_guest_sessions_streamId_status_idx" ON public.live_guest_sessions USING btree ("streamId", status);


--
-- Name: live_guest_sessions_streamId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "live_guest_sessions_streamId_userId_key" ON public.live_guest_sessions USING btree ("streamId", "userId");


--
-- Name: live_guest_sessions_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_guest_sessions_userId_idx" ON public.live_guest_sessions USING btree ("userId");


--
-- Name: live_session_messages_sessionId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_session_messages_sessionId_idx" ON public.live_session_messages USING btree ("sessionId");


--
-- Name: live_sessions_roomId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_sessions_roomId_idx" ON public.live_sessions USING btree ("roomId");


--
-- Name: live_sessions_roomId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "live_sessions_roomId_key" ON public.live_sessions USING btree ("roomId");


--
-- Name: live_sessions_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX live_sessions_status_idx ON public.live_sessions USING btree (status);


--
-- Name: live_sessions_tellerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_sessions_tellerId_idx" ON public.live_sessions USING btree ("tellerId");


--
-- Name: live_sessions_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_sessions_userId_idx" ON public.live_sessions USING btree ("userId");


--
-- Name: live_teller_reviews_sessionId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "live_teller_reviews_sessionId_key" ON public.live_teller_reviews USING btree ("sessionId");


--
-- Name: live_teller_reviews_tellerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "live_teller_reviews_tellerId_idx" ON public.live_teller_reviews USING btree ("tellerId");


--
-- Name: lucky_gift_rewards_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "lucky_gift_rewards_createdAt_idx" ON public.lucky_gift_rewards USING btree ("createdAt");


--
-- Name: lucky_gift_rewards_isJackpot_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "lucky_gift_rewards_isJackpot_createdAt_idx" ON public.lucky_gift_rewards USING btree ("isJackpot", "createdAt");


--
-- Name: lucky_gift_rewards_userId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "lucky_gift_rewards_userId_createdAt_idx" ON public.lucky_gift_rewards USING btree ("userId", "createdAt");


--
-- Name: lucky_gift_tiers_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "lucky_gift_tiers_isActive_idx" ON public.lucky_gift_tiers USING btree ("isActive");


--
-- Name: membership_badges_tier_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "membership_badges_tier_isActive_idx" ON public.membership_badges USING btree (tier, "isActive");


--
-- Name: membership_events_endsAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "membership_events_endsAt_idx" ON public.membership_events USING btree ("endsAt");


--
-- Name: membership_events_isActive_startsAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "membership_events_isActive_startsAt_idx" ON public.membership_events USING btree ("isActive", "startsAt");


--
-- Name: membership_features_category_sortOrder_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "membership_features_category_sortOrder_idx" ON public.membership_features USING btree (category, "sortOrder");


--
-- Name: membership_features_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "membership_features_isActive_idx" ON public.membership_features USING btree ("isActive");


--
-- Name: membership_features_key_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX membership_features_key_key ON public.membership_features USING btree (key);


--
-- Name: membership_grants_giverId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "membership_grants_giverId_idx" ON public.membership_grants USING btree ("giverId");


--
-- Name: membership_grants_receiverId_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "membership_grants_receiverId_status_idx" ON public.membership_grants USING btree ("receiverId", status);


--
-- Name: membership_grants_status_expiresAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "membership_grants_status_expiresAt_idx" ON public.membership_grants USING btree (status, "expiresAt");


--
-- Name: membership_grants_tierKey_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "membership_grants_tierKey_idx" ON public.membership_grants USING btree ("tierKey");


--
-- Name: membership_grants_transactionId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "membership_grants_transactionId_idx" ON public.membership_grants USING btree ("transactionId");


--
-- Name: membership_plans_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "membership_plans_isActive_idx" ON public.membership_plans USING btree ("isActive");


--
-- Name: membership_plans_priceType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "membership_plans_priceType_idx" ON public.membership_plans USING btree ("priceType");


--
-- Name: membership_plans_tier_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX membership_plans_tier_idx ON public.membership_plans USING btree (tier);


--
-- Name: membership_purchases_expiresAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "membership_purchases_expiresAt_idx" ON public.membership_purchases USING btree ("expiresAt");


--
-- Name: membership_purchases_planId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "membership_purchases_planId_idx" ON public.membership_purchases USING btree ("planId");


--
-- Name: membership_purchases_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX membership_purchases_status_idx ON public.membership_purchases USING btree (status);


--
-- Name: membership_purchases_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "membership_purchases_userId_idx" ON public.membership_purchases USING btree ("userId");


--
-- Name: membership_tier_defs_isActive_sortOrder_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "membership_tier_defs_isActive_sortOrder_idx" ON public.membership_tier_defs USING btree ("isActive", "sortOrder");


--
-- Name: membership_tier_defs_key_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX membership_tier_defs_key_key ON public.membership_tier_defs USING btree (key);


--
-- Name: membership_tier_defs_rank_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX membership_tier_defs_rank_idx ON public.membership_tier_defs USING btree (rank);


--
-- Name: membership_tier_features_featureKey_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "membership_tier_features_featureKey_idx" ON public.membership_tier_features USING btree ("featureKey");


--
-- Name: membership_tier_features_tierKey_enabled_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "membership_tier_features_tierKey_enabled_idx" ON public.membership_tier_features USING btree ("tierKey", enabled);


--
-- Name: membership_tier_features_tierKey_featureKey_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "membership_tier_features_tierKey_featureKey_key" ON public.membership_tier_features USING btree ("tierKey", "featureKey");


--
-- Name: message_requests_receiverId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "message_requests_receiverId_idx" ON public.message_requests USING btree ("receiverId");


--
-- Name: message_requests_senderId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "message_requests_senderId_idx" ON public.message_requests USING btree ("senderId");


--
-- Name: message_requests_senderId_receiverId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "message_requests_senderId_receiverId_key" ON public.message_requests USING btree ("senderId", "receiverId");


--
-- Name: message_requests_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX message_requests_status_idx ON public.message_requests USING btree (status);


--
-- Name: mic_frames_tier_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "mic_frames_tier_isActive_idx" ON public.mic_frames USING btree (tier, "isActive");


--
-- Name: mini_games_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "mini_games_isActive_idx" ON public.mini_games USING btree ("isActive");


--
-- Name: mini_games_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mini_games_slug_idx ON public.mini_games USING btree (slug);


--
-- Name: mini_games_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX mini_games_slug_key ON public.mini_games USING btree (slug);


--
-- Name: name_effects_key_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX name_effects_key_key ON public.name_effects USING btree (key);


--
-- Name: name_effects_tier_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "name_effects_tier_isActive_idx" ON public.name_effects USING btree (tier, "isActive");


--
-- Name: notifications_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "notifications_createdAt_idx" ON public.notifications USING btree ("createdAt");


--
-- Name: notifications_userId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "notifications_userId_createdAt_idx" ON public.notifications USING btree ("userId", "createdAt" DESC);


--
-- Name: notifications_userId_dedupeKey_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "notifications_userId_dedupeKey_createdAt_idx" ON public.notifications USING btree ("userId", "dedupeKey", "createdAt" DESC);


--
-- Name: notifications_userId_isRead_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "notifications_userId_isRead_createdAt_idx" ON public.notifications USING btree ("userId", "isRead", "createdAt" DESC);


--
-- Name: notifications_userId_isRead_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "notifications_userId_isRead_idx" ON public.notifications USING btree ("userId", "isRead");


--
-- Name: okey_match_players_matchId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "okey_match_players_matchId_idx" ON public.okey_match_players USING btree ("matchId");


--
-- Name: okey_match_players_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "okey_match_players_userId_idx" ON public.okey_match_players USING btree ("userId");


--
-- Name: okey_matches_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "okey_matches_createdAt_idx" ON public.okey_matches USING btree ("createdAt");


--
-- Name: okey_matches_mode_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX okey_matches_mode_status_idx ON public.okey_matches USING btree (mode, status);


--
-- Name: okey_matches_winnerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "okey_matches_winnerId_idx" ON public.okey_matches USING btree ("winnerId");


--
-- Name: online_fal_buttons_sortOrder_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "online_fal_buttons_sortOrder_idx" ON public.online_fal_buttons USING btree ("sortOrder");


--
-- Name: online_fal_sections_key_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX online_fal_sections_key_key ON public.online_fal_sections USING btree (key);


--
-- Name: online_fal_sections_sortOrder_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "online_fal_sections_sortOrder_idx" ON public.online_fal_sections USING btree ("sortOrder");


--
-- Name: password_reset_tokens_token_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX password_reset_tokens_token_idx ON public.password_reset_tokens USING btree (token);


--
-- Name: password_reset_tokens_token_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX password_reset_tokens_token_key ON public.password_reset_tokens USING btree (token);


--
-- Name: password_reset_tokens_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "password_reset_tokens_userId_idx" ON public.password_reset_tokens USING btree ("userId");


--
-- Name: payment_methods_type_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX payment_methods_type_key ON public.payment_methods USING btree (type);


--
-- Name: payment_notifications_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "payment_notifications_createdAt_idx" ON public.payment_notifications USING btree ("createdAt");


--
-- Name: payment_notifications_productType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "payment_notifications_productType_idx" ON public.payment_notifications USING btree ("productType");


--
-- Name: payment_notifications_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payment_notifications_status_idx ON public.payment_notifications USING btree (status);


--
-- Name: payment_notifications_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "payment_notifications_userId_idx" ON public.payment_notifications USING btree ("userId");


--
-- Name: payments_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payments_status_idx ON public.payments USING btree (status);


--
-- Name: payments_stripePaymentIntentId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "payments_stripePaymentIntentId_key" ON public.payments USING btree ("stripePaymentIntentId");


--
-- Name: payments_stripeSessionId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "payments_stripeSessionId_idx" ON public.payments USING btree ("stripeSessionId");


--
-- Name: payments_stripeSessionId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "payments_stripeSessionId_key" ON public.payments USING btree ("stripeSessionId");


--
-- Name: payments_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "payments_userId_idx" ON public.payments USING btree ("userId");


--
-- Name: permissions_group_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX permissions_group_idx ON public.permissions USING btree ("group");


--
-- Name: permissions_key_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX permissions_key_key ON public.permissions USING btree (key);


--
-- Name: phone_otps_idempotencyKey_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "phone_otps_idempotencyKey_idx" ON public.phone_otps USING btree ("idempotencyKey");


--
-- Name: phone_otps_phone_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX phone_otps_phone_idx ON public.phone_otps USING btree (phone);


--
-- Name: phone_otps_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "phone_otps_userId_idx" ON public.phone_otps USING btree ("userId");


--
-- Name: pk_bans_userId_active_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_bans_userId_active_idx" ON public.pk_bans USING btree ("userId", active);


--
-- Name: pk_battle_participants_battleId_side_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_battle_participants_battleId_side_idx" ON public.pk_battle_participants USING btree ("battleId", side);


--
-- Name: pk_battle_participants_battleId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "pk_battle_participants_battleId_userId_key" ON public.pk_battle_participants USING btree ("battleId", "userId");


--
-- Name: pk_battle_participants_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_battle_participants_userId_idx" ON public.pk_battle_participants USING btree ("userId");


--
-- Name: pk_battles_scopeRoomId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_battles_scopeRoomId_idx" ON public.pk_battles USING btree ("scopeRoomId");


--
-- Name: pk_battles_status_endsAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_battles_status_endsAt_idx" ON public.pk_battles USING btree (status, "endsAt");


--
-- Name: pk_battles_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pk_battles_status_idx ON public.pk_battles USING btree (status);


--
-- Name: pk_battles_stream1Id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_battles_stream1Id_idx" ON public.pk_battles USING btree ("stream1Id");


--
-- Name: pk_battles_stream2Id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_battles_stream2Id_idx" ON public.pk_battles USING btree ("stream2Id");


--
-- Name: pk_battles_user1Id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_battles_user1Id_idx" ON public.pk_battles USING btree ("user1Id");


--
-- Name: pk_battles_user2Id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_battles_user2Id_idx" ON public.pk_battles USING btree ("user2Id");


--
-- Name: pk_events_matchId_endsAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_events_matchId_endsAt_idx" ON public.pk_events USING btree ("matchId", "endsAt");


--
-- Name: pk_gifts_battleId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_gifts_battleId_idx" ON public.pk_gifts USING btree ("battleId");


--
-- Name: pk_gifts_battleId_side_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_gifts_battleId_side_idx" ON public.pk_gifts USING btree ("battleId", side);


--
-- Name: pk_gifts_senderId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_gifts_senderId_idx" ON public.pk_gifts USING btree ("senderId");


--
-- Name: pk_matches_guestStreamId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_matches_guestStreamId_idx" ON public.pk_matches USING btree ("guestStreamId");


--
-- Name: pk_matches_guestUserId_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_matches_guestUserId_status_idx" ON public.pk_matches USING btree ("guestUserId", status);


--
-- Name: pk_matches_hostStreamId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_matches_hostStreamId_idx" ON public.pk_matches USING btree ("hostStreamId");


--
-- Name: pk_matches_hostUserId_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_matches_hostUserId_status_idx" ON public.pk_matches USING btree ("hostUserId", status);


--
-- Name: pk_matches_status_endsAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_matches_status_endsAt_idx" ON public.pk_matches USING btree (status, "endsAt");


--
-- Name: pk_matches_status_mode_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pk_matches_status_mode_idx ON public.pk_matches USING btree (status, mode);


--
-- Name: pk_participants_finishedAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_participants_finishedAt_idx" ON public.pk_participants USING btree ("finishedAt");


--
-- Name: pk_participants_matchId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "pk_participants_matchId_userId_key" ON public.pk_participants USING btree ("matchId", "userId");


--
-- Name: pk_participants_outcome_finishedAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_participants_outcome_finishedAt_idx" ON public.pk_participants USING btree (outcome, "finishedAt");


--
-- Name: pk_participants_userId_finishedAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_participants_userId_finishedAt_idx" ON public.pk_participants USING btree ("userId", "finishedAt");


--
-- Name: pk_scores_battleId_contributorId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_scores_battleId_contributorId_idx" ON public.pk_scores USING btree ("battleId", "contributorId");


--
-- Name: pk_scores_battleId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_scores_battleId_idx" ON public.pk_scores USING btree ("battleId");


--
-- Name: pk_scores_battleId_side_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_scores_battleId_side_idx" ON public.pk_scores USING btree ("battleId", side);


--
-- Name: pk_seats_matchId_seatIndex_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "pk_seats_matchId_seatIndex_key" ON public.pk_seats USING btree ("matchId", "seatIndex");


--
-- Name: pk_seats_matchId_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_seats_matchId_status_idx" ON public.pk_seats USING btree ("matchId", status);


--
-- Name: pk_seats_userId_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_seats_userId_status_idx" ON public.pk_seats USING btree ("userId", status);


--
-- Name: pk_stats_totalScore_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "pk_stats_totalScore_idx" ON public.pk_stats USING btree ("totalScore");


--
-- Name: pk_stats_wins_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pk_stats_wins_idx ON public.pk_stats USING btree (wins);


--
-- Name: platform_settings_key_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX platform_settings_key_key ON public.platform_settings USING btree (key);


--
-- Name: profile_frames_tier_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "profile_frames_tier_isActive_idx" ON public.profile_frames USING btree (tier, "isActive");


--
-- Name: profile_views_viewedAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "profile_views_viewedAt_idx" ON public.profile_views USING btree ("viewedAt");


--
-- Name: profile_views_viewedUserId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "profile_views_viewedUserId_idx" ON public.profile_views USING btree ("viewedUserId");


--
-- Name: profile_visits_profileId_visitedAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "profile_visits_profileId_visitedAt_idx" ON public.profile_visits USING btree ("profileId", "visitedAt");


--
-- Name: profile_visits_visitorId_profileId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "profile_visits_visitorId_profileId_key" ON public.profile_visits USING btree ("visitorId", "profileId");


--
-- Name: profile_visits_visitorId_visitedAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "profile_visits_visitorId_visitedAt_idx" ON public.profile_visits USING btree ("visitorId", "visitedAt");


--
-- Name: push_notification_logs_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "push_notification_logs_createdAt_idx" ON public.push_notification_logs USING btree ("createdAt");


--
-- Name: push_notification_logs_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX push_notification_logs_status_idx ON public.push_notification_logs USING btree (status);


--
-- Name: push_notification_logs_targetType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "push_notification_logs_targetType_idx" ON public.push_notification_logs USING btree ("targetType");


--
-- Name: referral_commissions_agencyId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "referral_commissions_agencyId_createdAt_idx" ON public.referral_commissions USING btree ("agencyId", "createdAt");


--
-- Name: referral_commissions_commissionType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "referral_commissions_commissionType_idx" ON public.referral_commissions USING btree ("commissionType");


--
-- Name: referral_commissions_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "referral_commissions_createdAt_idx" ON public.referral_commissions USING btree ("createdAt");


--
-- Name: referral_commissions_earnerId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "referral_commissions_earnerId_createdAt_idx" ON public.referral_commissions USING btree ("earnerId", "createdAt");


--
-- Name: referral_commissions_sourceUserId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "referral_commissions_sourceUserId_idx" ON public.referral_commissions USING btree ("sourceUserId");


--
-- Name: referrals_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "referrals_createdAt_idx" ON public.referrals USING btree ("createdAt");


--
-- Name: referrals_referrerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "referrals_referrerId_idx" ON public.referrals USING btree ("referrerId");


--
-- Name: referrals_referrerId_referredId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "referrals_referrerId_referredId_key" ON public.referrals USING btree ("referrerId", "referredId");


--
-- Name: refund_requests_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "refund_requests_createdAt_idx" ON public.refund_requests USING btree ("createdAt");


--
-- Name: refund_requests_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX refund_requests_status_idx ON public.refund_requests USING btree (status);


--
-- Name: refund_requests_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "refund_requests_userId_idx" ON public.refund_requests USING btree ("userId");


--
-- Name: remote_configs_group_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX remote_configs_group_idx ON public.remote_configs USING btree ("group");


--
-- Name: remote_configs_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX remote_configs_key_idx ON public.remote_configs USING btree (key);


--
-- Name: remote_configs_key_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX remote_configs_key_key ON public.remote_configs USING btree (key);


--
-- Name: revenue_rules_context_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX revenue_rules_context_key ON public.revenue_rules USING btree (context);


--
-- Name: revoked_tokens_expiresAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "revoked_tokens_expiresAt_idx" ON public.revoked_tokens USING btree ("expiresAt");


--
-- Name: revoked_tokens_tokenHash_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "revoked_tokens_tokenHash_key" ON public.revoked_tokens USING btree ("tokenHash");


--
-- Name: revoked_tokens_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "revoked_tokens_userId_idx" ON public.revoked_tokens USING btree ("userId");


--
-- Name: risk_events_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX risk_events_category_idx ON public.risk_events USING btree (category);


--
-- Name: risk_events_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "risk_events_createdAt_idx" ON public.risk_events USING btree ("createdAt");


--
-- Name: risk_events_level_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX risk_events_level_idx ON public.risk_events USING btree (level);


--
-- Name: risk_events_reviewed_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX risk_events_reviewed_idx ON public.risk_events USING btree (reviewed);


--
-- Name: risk_events_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "risk_events_userId_idx" ON public.risk_events USING btree ("userId");


--
-- Name: role_permissions_permissionId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "role_permissions_permissionId_idx" ON public.role_permissions USING btree ("permissionId");


--
-- Name: role_permissions_roleId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "role_permissions_roleId_idx" ON public.role_permissions USING btree ("roleId");


--
-- Name: role_permissions_roleId_permissionId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "role_permissions_roleId_permissionId_key" ON public.role_permissions USING btree ("roleId", "permissionId");


--
-- Name: roles_key_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX roles_key_key ON public.roles USING btree (key);


--
-- Name: roles_level_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX roles_level_idx ON public.roles USING btree (level);


--
-- Name: room_revenue_logs_eventType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "room_revenue_logs_eventType_idx" ON public.room_revenue_logs USING btree ("eventType");


--
-- Name: room_revenue_logs_roomId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "room_revenue_logs_roomId_createdAt_idx" ON public.room_revenue_logs USING btree ("roomId", "createdAt");


--
-- Name: room_signals_receiverId_processed_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "room_signals_receiverId_processed_idx" ON public.room_signals USING btree ("receiverId", processed);


--
-- Name: room_signals_sessionId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "room_signals_sessionId_idx" ON public.room_signals USING btree ("sessionId");


--
-- Name: room_themes_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX room_themes_category_idx ON public.room_themes USING btree (category);


--
-- Name: room_themes_contentVersion_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "room_themes_contentVersion_idx" ON public.room_themes USING btree ("contentVersion");


--
-- Name: room_themes_tier_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "room_themes_tier_isActive_idx" ON public.room_themes USING btree (tier, "isActive");


--
-- Name: rtc_telemetry_contextId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "rtc_telemetry_contextId_idx" ON public.rtc_telemetry USING btree ("contextId");


--
-- Name: rtc_telemetry_context_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rtc_telemetry_context_idx ON public.rtc_telemetry USING btree (context);


--
-- Name: rtc_telemetry_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "rtc_telemetry_createdAt_idx" ON public.rtc_telemetry USING btree ("createdAt");


--
-- Name: rtc_telemetry_qualityLevel_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "rtc_telemetry_qualityLevel_idx" ON public.rtc_telemetry USING btree ("qualityLevel");


--
-- Name: rtc_telemetry_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "rtc_telemetry_userId_idx" ON public.rtc_telemetry USING btree ("userId");


--
-- Name: sessions_sessionToken_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "sessions_sessionToken_key" ON public.sessions USING btree ("sessionToken");


--
-- Name: sessions_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "sessions_userId_idx" ON public.sessions USING btree ("userId");


--
-- Name: share_events_scope_targetId_userId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "share_events_scope_targetId_userId_createdAt_idx" ON public.share_events USING btree (scope, "targetId", "userId", "createdAt");


--
-- Name: share_events_userId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "share_events_userId_createdAt_idx" ON public.share_events USING btree ("userId", "createdAt");


--
-- Name: short_video_comment_likes_commentId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_video_comment_likes_commentId_idx" ON public.short_video_comment_likes USING btree ("commentId");


--
-- Name: short_video_comment_likes_commentId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "short_video_comment_likes_commentId_userId_key" ON public.short_video_comment_likes USING btree ("commentId", "userId");


--
-- Name: short_video_comment_likes_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_video_comment_likes_userId_idx" ON public.short_video_comment_likes USING btree ("userId");


--
-- Name: short_video_comments_parentId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_video_comments_parentId_idx" ON public.short_video_comments USING btree ("parentId");


--
-- Name: short_video_comments_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_video_comments_userId_idx" ON public.short_video_comments USING btree ("userId");


--
-- Name: short_video_comments_videoId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_video_comments_videoId_createdAt_idx" ON public.short_video_comments USING btree ("videoId", "createdAt" DESC);


--
-- Name: short_video_comments_videoId_parentId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_video_comments_videoId_parentId_createdAt_idx" ON public.short_video_comments USING btree ("videoId", "parentId", "createdAt" DESC);


--
-- Name: short_video_hashtags_hashtagId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_video_hashtags_hashtagId_createdAt_idx" ON public.short_video_hashtags USING btree ("hashtagId", "createdAt" DESC);


--
-- Name: short_video_hashtags_videoId_hashtagId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "short_video_hashtags_videoId_hashtagId_key" ON public.short_video_hashtags USING btree ("videoId", "hashtagId");


--
-- Name: short_video_hashtags_videoId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_video_hashtags_videoId_idx" ON public.short_video_hashtags USING btree ("videoId");


--
-- Name: short_video_likes_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_video_likes_userId_idx" ON public.short_video_likes USING btree ("userId");


--
-- Name: short_video_likes_videoId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_video_likes_videoId_idx" ON public.short_video_likes USING btree ("videoId");


--
-- Name: short_video_likes_videoId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "short_video_likes_videoId_userId_key" ON public.short_video_likes USING btree ("videoId", "userId");


--
-- Name: short_video_mentions_mentionedUserId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_video_mentions_mentionedUserId_idx" ON public.short_video_mentions USING btree ("mentionedUserId");


--
-- Name: short_video_mentions_videoId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_video_mentions_videoId_idx" ON public.short_video_mentions USING btree ("videoId");


--
-- Name: short_video_mentions_videoId_mentionedUserId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "short_video_mentions_videoId_mentionedUserId_key" ON public.short_video_mentions USING btree ("videoId", "mentionedUserId");


--
-- Name: short_video_music_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_video_music_isActive_idx" ON public.short_video_music USING btree ("isActive");


--
-- Name: short_video_music_usesCount_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_video_music_usesCount_idx" ON public.short_video_music USING btree ("usesCount" DESC);


--
-- Name: short_video_saves_userId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_video_saves_userId_createdAt_idx" ON public.short_video_saves USING btree ("userId", "createdAt" DESC);


--
-- Name: short_video_saves_videoId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_video_saves_videoId_idx" ON public.short_video_saves USING btree ("videoId");


--
-- Name: short_video_saves_videoId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "short_video_saves_videoId_userId_key" ON public.short_video_saves USING btree ("videoId", "userId");


--
-- Name: short_video_views_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_video_views_userId_idx" ON public.short_video_views USING btree ("userId");


--
-- Name: short_video_views_videoId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_video_views_videoId_idx" ON public.short_video_views USING btree ("videoId");


--
-- Name: short_video_views_videoId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "short_video_views_videoId_userId_key" ON public.short_video_views USING btree ("videoId", "userId");


--
-- Name: short_videos_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_videos_createdAt_idx" ON public.short_videos USING btree ("createdAt" DESC);


--
-- Name: short_videos_duetOfId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_videos_duetOfId_idx" ON public.short_videos USING btree ("duetOfId");


--
-- Name: short_videos_musicId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_videos_musicId_idx" ON public.short_videos USING btree ("musicId");


--
-- Name: short_videos_userId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_videos_userId_createdAt_idx" ON public.short_videos USING btree ("userId", "createdAt" DESC);


--
-- Name: short_videos_visibility_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "short_videos_visibility_createdAt_idx" ON public.short_videos USING btree (visibility, "createdAt" DESC);


--
-- Name: site_announcements_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "site_announcements_createdAt_idx" ON public.site_announcements USING btree ("createdAt");


--
-- Name: site_announcements_expiresAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "site_announcements_expiresAt_idx" ON public.site_announcements USING btree ("expiresAt");


--
-- Name: site_pages_isPublished_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "site_pages_isPublished_idx" ON public.site_pages USING btree ("isPublished");


--
-- Name: site_pages_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX site_pages_slug_idx ON public.site_pages USING btree (slug);


--
-- Name: site_pages_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX site_pages_slug_key ON public.site_pages USING btree (slug);


--
-- Name: site_pages_sortOrder_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "site_pages_sortOrder_idx" ON public.site_pages USING btree ("sortOrder");


--
-- Name: site_presences_lastSeen_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "site_presences_lastSeen_idx" ON public.site_presences USING btree ("lastSeen");


--
-- Name: site_presences_visitorId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "site_presences_visitorId_key" ON public.site_presences USING btree ("visitorId");


--
-- Name: site_settings_key_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX site_settings_key_key ON public.site_settings USING btree (key);


--
-- Name: site_visits_country_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX site_visits_country_idx ON public.site_visits USING btree (country);


--
-- Name: site_visits_visitedAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "site_visits_visitedAt_idx" ON public.site_visits USING btree ("visitedAt");


--
-- Name: site_visits_visitorId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "site_visits_visitorId_idx" ON public.site_visits USING btree ("visitorId");


--
-- Name: sms_delivery_logs_idempotencyKey_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "sms_delivery_logs_idempotencyKey_idx" ON public.sms_delivery_logs USING btree ("idempotencyKey");


--
-- Name: sms_delivery_logs_providerKey_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "sms_delivery_logs_providerKey_createdAt_idx" ON public.sms_delivery_logs USING btree ("providerKey", "createdAt");


--
-- Name: sms_provider_configs_providerKey_fieldKey_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "sms_provider_configs_providerKey_fieldKey_key" ON public.sms_provider_configs USING btree ("providerKey", "fieldKey");


--
-- Name: sms_provider_health_providerKey_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "sms_provider_health_providerKey_key" ON public.sms_provider_health USING btree ("providerKey");


--
-- Name: sms_providers_enabled_priority_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sms_providers_enabled_priority_idx ON public.sms_providers USING btree (enabled, priority);


--
-- Name: sms_providers_providerKey_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "sms_providers_providerKey_key" ON public.sms_providers USING btree ("providerKey");


--
-- Name: social_actions_actorId_targetId_type_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "social_actions_actorId_targetId_type_key" ON public.social_actions USING btree ("actorId", "targetId", type);


--
-- Name: social_actions_actorId_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "social_actions_actorId_type_idx" ON public.social_actions USING btree ("actorId", type);


--
-- Name: social_actions_targetId_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "social_actions_targetId_type_idx" ON public.social_actions USING btree ("targetId", type);


--
-- Name: social_comments_postId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "social_comments_postId_idx" ON public.social_comments USING btree ("postId");


--
-- Name: social_comments_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "social_comments_userId_idx" ON public.social_comments USING btree ("userId");


--
-- Name: social_likes_postId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "social_likes_postId_idx" ON public.social_likes USING btree ("postId");


--
-- Name: social_likes_postId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "social_likes_postId_userId_key" ON public.social_likes USING btree ("postId", "userId");


--
-- Name: social_posts_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "social_posts_createdAt_idx" ON public.social_posts USING btree ("createdAt");


--
-- Name: social_posts_postType_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "social_posts_postType_createdAt_idx" ON public.social_posts USING btree ("postType", "createdAt" DESC);


--
-- Name: social_posts_postType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "social_posts_postType_idx" ON public.social_posts USING btree ("postType");


--
-- Name: social_posts_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "social_posts_userId_idx" ON public.social_posts USING btree ("userId");


--
-- Name: sos_game_chats_gameId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "sos_game_chats_gameId_createdAt_idx" ON public.sos_game_chats USING btree ("gameId", "createdAt");


--
-- Name: sos_game_viewers_gameId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "sos_game_viewers_gameId_idx" ON public.sos_game_viewers USING btree ("gameId");


--
-- Name: sos_game_viewers_gameId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "sos_game_viewers_gameId_userId_key" ON public.sos_game_viewers USING btree ("gameId", "userId");


--
-- Name: sos_games_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "sos_games_createdAt_idx" ON public.sos_games USING btree ("createdAt");


--
-- Name: sos_games_player1Id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "sos_games_player1Id_idx" ON public.sos_games USING btree ("player1Id");


--
-- Name: sos_games_player2Id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "sos_games_player2Id_idx" ON public.sos_games USING btree ("player2Id");


--
-- Name: sos_games_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sos_games_status_idx ON public.sos_games USING btree (status);


--
-- Name: sos_games_status_isAI_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "sos_games_status_isAI_idx" ON public.sos_games USING btree (status, "isAI");


--
-- Name: store_purchases_provider_purchaseToken_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "store_purchases_provider_purchaseToken_key" ON public.store_purchases USING btree (provider, "purchaseToken");


--
-- Name: store_purchases_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX store_purchases_status_idx ON public.store_purchases USING btree (status);


--
-- Name: store_purchases_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "store_purchases_userId_idx" ON public.store_purchases USING btree ("userId");


--
-- Name: stream_bans_streamId_bannedUserId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "stream_bans_streamId_bannedUserId_key" ON public.stream_bans USING btree ("streamId", "bannedUserId");


--
-- Name: stream_bans_streamId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "stream_bans_streamId_idx" ON public.stream_bans USING btree ("streamId");


--
-- Name: stream_co_broadcasters_streamId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "stream_co_broadcasters_streamId_idx" ON public.stream_co_broadcasters USING btree ("streamId");


--
-- Name: stream_co_broadcasters_streamId_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "stream_co_broadcasters_streamId_status_idx" ON public.stream_co_broadcasters USING btree ("streamId", status);


--
-- Name: stream_co_broadcasters_streamId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "stream_co_broadcasters_streamId_userId_key" ON public.stream_co_broadcasters USING btree ("streamId", "userId");


--
-- Name: stream_co_broadcasters_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "stream_co_broadcasters_userId_idx" ON public.stream_co_broadcasters USING btree ("userId");


--
-- Name: stream_fortune_requests_jetonAmount_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "stream_fortune_requests_jetonAmount_idx" ON public.stream_fortune_requests USING btree ("jetonAmount");


--
-- Name: stream_fortune_requests_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX stream_fortune_requests_status_idx ON public.stream_fortune_requests USING btree (status);


--
-- Name: stream_fortune_requests_streamId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "stream_fortune_requests_streamId_idx" ON public.stream_fortune_requests USING btree ("streamId");


--
-- Name: stream_fortune_requests_streamId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "stream_fortune_requests_streamId_userId_key" ON public.stream_fortune_requests USING btree ("streamId", "userId");


--
-- Name: stream_fortune_requests_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "stream_fortune_requests_userId_idx" ON public.stream_fortune_requests USING btree ("userId");


--
-- Name: stream_gifts_senderId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "stream_gifts_senderId_idx" ON public.stream_gifts USING btree ("senderId");


--
-- Name: stream_gifts_streamId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "stream_gifts_streamId_idx" ON public.stream_gifts USING btree ("streamId");


--
-- Name: stream_moderators_streamId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "stream_moderators_streamId_idx" ON public.stream_moderators USING btree ("streamId");


--
-- Name: stream_moderators_streamId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "stream_moderators_streamId_userId_key" ON public.stream_moderators USING btree ("streamId", "userId");


--
-- Name: stream_moderators_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "stream_moderators_userId_idx" ON public.stream_moderators USING btree ("userId");


--
-- Name: stream_muted_viewers_streamId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "stream_muted_viewers_streamId_idx" ON public.stream_muted_viewers USING btree ("streamId");


--
-- Name: stream_muted_viewers_streamId_viewerId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "stream_muted_viewers_streamId_viewerId_key" ON public.stream_muted_viewers USING btree ("streamId", "viewerId");


--
-- Name: support_messages_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "support_messages_createdAt_idx" ON public.support_messages USING btree ("createdAt");


--
-- Name: support_messages_senderId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "support_messages_senderId_idx" ON public.support_messages USING btree ("senderId");


--
-- Name: support_messages_ticketId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "support_messages_ticketId_idx" ON public.support_messages USING btree ("ticketId");


--
-- Name: support_tickets_assignedTo_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "support_tickets_assignedTo_idx" ON public.support_tickets USING btree ("assignedTo");


--
-- Name: support_tickets_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX support_tickets_category_idx ON public.support_tickets USING btree (category);


--
-- Name: support_tickets_lastMessageAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "support_tickets_lastMessageAt_idx" ON public.support_tickets USING btree ("lastMessageAt");


--
-- Name: support_tickets_relatedType_relatedId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "support_tickets_relatedType_relatedId_idx" ON public.support_tickets USING btree ("relatedType", "relatedId");


--
-- Name: support_tickets_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX support_tickets_status_idx ON public.support_tickets USING btree (status);


--
-- Name: support_tickets_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "support_tickets_userId_idx" ON public.support_tickets USING btree ("userId");


--
-- Name: supporter_levels_broadcasterId_totalContributed_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "supporter_levels_broadcasterId_totalContributed_idx" ON public.supporter_levels USING btree ("broadcasterId", "totalContributed");


--
-- Name: supporter_levels_level_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX supporter_levels_level_idx ON public.supporter_levels USING btree (level);


--
-- Name: supporter_levels_userId_broadcasterId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "supporter_levels_userId_broadcasterId_key" ON public.supporter_levels USING btree ("userId", "broadcasterId");


--
-- Name: supporter_levels_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "supporter_levels_userId_idx" ON public.supporter_levels USING btree ("userId");


--
-- Name: team_members_teamId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "team_members_teamId_idx" ON public.team_members USING btree ("teamId");


--
-- Name: team_members_teamId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "team_members_teamId_userId_key" ON public.team_members USING btree ("teamId", "userId");


--
-- Name: team_members_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "team_members_userId_idx" ON public.team_members USING btree ("userId");


--
-- Name: teams_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "teams_isActive_idx" ON public.teams USING btree ("isActive");


--
-- Name: teams_ownerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "teams_ownerId_idx" ON public.teams USING btree ("ownerId");


--
-- Name: teams_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX teams_slug_key ON public.teams USING btree (slug);


--
-- Name: teams_totalPoints_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "teams_totalPoints_idx" ON public.teams USING btree ("totalPoints");


--
-- Name: teller_awards_awardType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "teller_awards_awardType_idx" ON public.teller_awards USING btree ("awardType");


--
-- Name: teller_awards_endDate_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "teller_awards_endDate_idx" ON public.teller_awards USING btree ("endDate");


--
-- Name: teller_awards_tellerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "teller_awards_tellerId_idx" ON public.teller_awards USING btree ("tellerId");


--
-- Name: teller_chat_messages_chatSessionId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "teller_chat_messages_chatSessionId_idx" ON public.teller_chat_messages USING btree ("chatSessionId");


--
-- Name: teller_chat_messages_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "teller_chat_messages_createdAt_idx" ON public.teller_chat_messages USING btree ("createdAt");


--
-- Name: teller_chat_sessions_liveSessionId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "teller_chat_sessions_liveSessionId_key" ON public.teller_chat_sessions USING btree ("liveSessionId");


--
-- Name: teller_chat_sessions_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX teller_chat_sessions_status_idx ON public.teller_chat_sessions USING btree (status);


--
-- Name: teller_chat_sessions_tellerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "teller_chat_sessions_tellerId_idx" ON public.teller_chat_sessions USING btree ("tellerId");


--
-- Name: teller_chat_sessions_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "teller_chat_sessions_userId_idx" ON public.teller_chat_sessions USING btree ("userId");


--
-- Name: teller_gifts_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "teller_gifts_createdAt_idx" ON public.teller_gifts USING btree ("createdAt");


--
-- Name: teller_gifts_senderId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "teller_gifts_senderId_idx" ON public.teller_gifts USING btree ("senderId");


--
-- Name: teller_gifts_tellerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "teller_gifts_tellerId_idx" ON public.teller_gifts USING btree ("tellerId");


--
-- Name: teller_warnings_tellerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "teller_warnings_tellerId_idx" ON public.teller_warnings USING btree ("tellerId");


--
-- Name: ticker_messages_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ticker_messages_isActive_idx" ON public.ticker_messages USING btree ("isActive");


--
-- Name: tiktok_categories_isActive_sortOrder_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "tiktok_categories_isActive_sortOrder_idx" ON public.tiktok_categories USING btree ("isActive", "sortOrder");


--
-- Name: tiktok_categories_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX tiktok_categories_slug_key ON public.tiktok_categories USING btree (slug);


--
-- Name: tiktok_videos_categoryId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "tiktok_videos_categoryId_idx" ON public.tiktok_videos USING btree ("categoryId");


--
-- Name: tiktok_videos_isActive_sortOrder_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "tiktok_videos_isActive_sortOrder_idx" ON public.tiktok_videos USING btree ("isActive", "sortOrder");


--
-- Name: topup_bonus_tiers_currency_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX topup_bonus_tiers_currency_idx ON public.topup_bonus_tiers USING btree (currency);


--
-- Name: topup_bonus_tiers_isActive_minAmount_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "topup_bonus_tiers_isActive_minAmount_idx" ON public.topup_bonus_tiers USING btree ("isActive", "minAmount");


--
-- Name: tournament_matches_roundId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "tournament_matches_roundId_idx" ON public.tournament_matches USING btree ("roundId");


--
-- Name: tournament_matches_side1Id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "tournament_matches_side1Id_idx" ON public.tournament_matches USING btree ("side1Id");


--
-- Name: tournament_matches_side2Id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "tournament_matches_side2Id_idx" ON public.tournament_matches USING btree ("side2Id");


--
-- Name: tournament_rounds_tournamentId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "tournament_rounds_tournamentId_idx" ON public.tournament_rounds USING btree ("tournamentId");


--
-- Name: tournament_rounds_tournamentId_roundNumber_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "tournament_rounds_tournamentId_roundNumber_key" ON public.tournament_rounds USING btree ("tournamentId", "roundNumber");


--
-- Name: translations_languageCode_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "translations_languageCode_idx" ON public.translations USING btree ("languageCode");


--
-- Name: translations_languageCode_translationKey_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "translations_languageCode_translationKey_key" ON public.translations USING btree ("languageCode", "translationKey");


--
-- Name: trend_video_categories_isActive_sortOrder_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "trend_video_categories_isActive_sortOrder_idx" ON public.trend_video_categories USING btree ("isActive", "sortOrder");


--
-- Name: trend_video_categories_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX trend_video_categories_slug_key ON public.trend_video_categories USING btree (slug);


--
-- Name: trend_videos_categoryId_sortOrder_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "trend_videos_categoryId_sortOrder_idx" ON public.trend_videos USING btree ("categoryId", "sortOrder");


--
-- Name: trend_videos_isActive_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "trend_videos_isActive_createdAt_idx" ON public.trend_videos USING btree ("isActive", "createdAt");


--
-- Name: trending_topics_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trending_topics_category_idx ON public.trending_topics USING btree (category);


--
-- Name: trending_topics_isActive_trendScore_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "trending_topics_isActive_trendScore_idx" ON public.trending_topics USING btree ("isActive", "trendScore");


--
-- Name: trending_topics_isPinned_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "trending_topics_isPinned_idx" ON public.trending_topics USING btree ("isPinned");


--
-- Name: trending_topics_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX trending_topics_slug_key ON public.trending_topics USING btree (slug);


--
-- Name: trtc_webhook_logs_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "trtc_webhook_logs_createdAt_idx" ON public.trtc_webhook_logs USING btree ("createdAt");


--
-- Name: trtc_webhook_logs_eventGroupId_eventType_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "trtc_webhook_logs_eventGroupId_eventType_idx" ON public.trtc_webhook_logs USING btree ("eventGroupId", "eventType");


--
-- Name: trtc_webhook_logs_roomId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "trtc_webhook_logs_roomId_idx" ON public.trtc_webhook_logs USING btree ("roomId");


--
-- Name: trtc_webhook_logs_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "trtc_webhook_logs_userId_idx" ON public.trtc_webhook_logs USING btree ("userId");


--
-- Name: user_achievements_userId_achievementId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "user_achievements_userId_achievementId_key" ON public.user_achievements USING btree ("userId", "achievementId");


--
-- Name: user_achievements_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_achievements_userId_idx" ON public.user_achievements USING btree ("userId");


--
-- Name: user_blocks_blockedId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_blocks_blockedId_idx" ON public.user_blocks USING btree ("blockedId");


--
-- Name: user_blocks_blockerId_blockedId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "user_blocks_blockerId_blockedId_key" ON public.user_blocks USING btree ("blockerId", "blockedId");


--
-- Name: user_blocks_blockerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_blocks_blockerId_idx" ON public.user_blocks USING btree ("blockerId");


--
-- Name: user_daily_activity_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_daily_activity_date_idx ON public.user_daily_activity USING btree (date);


--
-- Name: user_daily_activity_userId_date_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "user_daily_activity_userId_date_key" ON public.user_daily_activity USING btree ("userId", date);


--
-- Name: user_daily_activity_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_daily_activity_userId_idx" ON public.user_daily_activity USING btree ("userId");


--
-- Name: user_devices_token_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_devices_token_idx ON public.user_devices USING btree (token);


--
-- Name: user_devices_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_devices_userId_idx" ON public.user_devices USING btree ("userId");


--
-- Name: user_devices_userId_token_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "user_devices_userId_token_key" ON public.user_devices USING btree ("userId", token);


--
-- Name: user_fortune_streaks_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_fortune_streaks_userId_idx" ON public.user_fortune_streaks USING btree ("userId");


--
-- Name: user_fortune_streaks_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "user_fortune_streaks_userId_key" ON public.user_fortune_streaks USING btree ("userId");


--
-- Name: user_game_profiles_referralCode_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "user_game_profiles_referralCode_key" ON public.user_game_profiles USING btree ("referralCode");


--
-- Name: user_game_profiles_totalJetons_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_game_profiles_totalJetons_idx" ON public.user_game_profiles USING btree ("totalJetons");


--
-- Name: user_game_profiles_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_game_profiles_userId_idx" ON public.user_game_profiles USING btree ("userId");


--
-- Name: user_game_profiles_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "user_game_profiles_userId_key" ON public.user_game_profiles USING btree ("userId");


--
-- Name: user_hourly_activity_userId_hour_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "user_hourly_activity_userId_hour_key" ON public.user_hourly_activity USING btree ("userId", hour);


--
-- Name: user_hourly_activity_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_hourly_activity_userId_idx" ON public.user_hourly_activity USING btree ("userId");


--
-- Name: user_login_sessions_loginAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_login_sessions_loginAt_idx" ON public.user_login_sessions USING btree ("loginAt");


--
-- Name: user_login_sessions_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_login_sessions_userId_idx" ON public.user_login_sessions USING btree ("userId");


--
-- Name: user_mission_progress_userId_dayKey_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_mission_progress_userId_dayKey_idx" ON public.user_mission_progress USING btree ("userId", "dayKey");


--
-- Name: user_mission_progress_userId_missionId_dayKey_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "user_mission_progress_userId_missionId_dayKey_key" ON public.user_mission_progress USING btree ("userId", "missionId", "dayKey");


--
-- Name: user_online_events_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_online_events_createdAt_idx" ON public.user_online_events USING btree ("createdAt");


--
-- Name: user_online_events_userId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_online_events_userId_createdAt_idx" ON public.user_online_events USING btree ("userId", "createdAt");


--
-- Name: user_permission_overrides_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_permission_overrides_userId_idx" ON public.user_permission_overrides USING btree ("userId");


--
-- Name: user_permission_overrides_userId_permissionKey_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "user_permission_overrides_userId_permissionKey_key" ON public.user_permission_overrides USING btree ("userId", "permissionKey");


--
-- Name: user_reports_reportedId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_reports_reportedId_idx" ON public.user_reports USING btree ("reportedId");


--
-- Name: user_reports_reporterId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_reports_reporterId_idx" ON public.user_reports USING btree ("reporterId");


--
-- Name: user_reports_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_reports_status_idx ON public.user_reports USING btree (status);


--
-- Name: user_stories_expiresAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_stories_expiresAt_idx" ON public.user_stories USING btree ("expiresAt");


--
-- Name: user_stories_userId_isActive_expiresAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_stories_userId_isActive_expiresAt_idx" ON public.user_stories USING btree ("userId", "isActive", "expiresAt");


--
-- Name: user_timeline_events_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_timeline_events_type_idx ON public.user_timeline_events USING btree (type);


--
-- Name: user_timeline_events_userId_occurredAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_timeline_events_userId_occurredAt_idx" ON public.user_timeline_events USING btree ("userId", "occurredAt");


--
-- Name: user_vip_preferences_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "user_vip_preferences_userId_key" ON public.user_vip_preferences USING btree ("userId");


--
-- Name: user_warnings_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_warnings_createdAt_idx" ON public.user_warnings USING btree ("createdAt");


--
-- Name: user_warnings_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_warnings_userId_idx" ON public.user_warnings USING btree ("userId");


--
-- Name: users_customUserId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "users_customUserId_idx" ON public.users USING btree ("customUserId");


--
-- Name: users_email_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_key ON public.users USING btree (email);


--
-- Name: users_isBot_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "users_isBot_idx" ON public.users USING btree ("isBot");


--
-- Name: users_referralCode_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "users_referralCode_idx" ON public.users USING btree ("referralCode");


--
-- Name: users_referralCode_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "users_referralCode_key" ON public.users USING btree ("referralCode");


--
-- Name: users_referredById_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "users_referredById_idx" ON public.users USING btree ("referredById");


--
-- Name: users_username_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_username_idx ON public.users USING btree (username);


--
-- Name: users_username_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_username_key ON public.users USING btree (username);


--
-- Name: verification_tokens_identifier_token_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX verification_tokens_identifier_token_key ON public.verification_tokens USING btree (identifier, token);


--
-- Name: verification_tokens_token_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX verification_tokens_token_key ON public.verification_tokens USING btree (token);


--
-- Name: verifications_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "verifications_createdAt_idx" ON public.verifications USING btree ("createdAt");


--
-- Name: verifications_reviewedBy_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "verifications_reviewedBy_idx" ON public.verifications USING btree ("reviewedBy");


--
-- Name: verifications_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX verifications_status_idx ON public.verifications USING btree (status);


--
-- Name: verifications_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX verifications_type_idx ON public.verifications USING btree (type);


--
-- Name: verifications_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "verifications_userId_idx" ON public.verifications USING btree ("userId");


--
-- Name: video_stream_comments_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "video_stream_comments_createdAt_idx" ON public.video_stream_comments USING btree ("createdAt");


--
-- Name: video_stream_comments_streamId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "video_stream_comments_streamId_idx" ON public.video_stream_comments USING btree ("streamId");


--
-- Name: video_stream_likes_streamId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "video_stream_likes_streamId_idx" ON public.video_stream_likes USING btree ("streamId");


--
-- Name: video_stream_likes_streamId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "video_stream_likes_streamId_userId_key" ON public.video_stream_likes USING btree ("streamId", "userId");


--
-- Name: video_stream_signals_receiverId_processed_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "video_stream_signals_receiverId_processed_idx" ON public.video_stream_signals USING btree ("receiverId", processed);


--
-- Name: video_stream_signals_streamId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "video_stream_signals_streamId_idx" ON public.video_stream_signals USING btree ("streamId");


--
-- Name: video_stream_viewers_streamId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "video_stream_viewers_streamId_idx" ON public.video_stream_viewers USING btree ("streamId");


--
-- Name: video_stream_viewers_streamId_leftAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "video_stream_viewers_streamId_leftAt_idx" ON public.video_stream_viewers USING btree ("streamId", "leftAt");


--
-- Name: video_stream_viewers_streamId_viewerId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "video_stream_viewers_streamId_viewerId_key" ON public.video_stream_viewers USING btree ("streamId", "viewerId");


--
-- Name: video_streams_roomId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "video_streams_roomId_key" ON public.video_streams USING btree ("roomId");


--
-- Name: video_streams_startedAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "video_streams_startedAt_idx" ON public.video_streams USING btree ("startedAt");


--
-- Name: video_streams_status_category_startedAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "video_streams_status_category_startedAt_idx" ON public.video_streams USING btree (status, category, "startedAt" DESC);


--
-- Name: video_streams_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX video_streams_status_idx ON public.video_streams USING btree (status);


--
-- Name: video_streams_status_startedAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "video_streams_status_startedAt_idx" ON public.video_streams USING btree (status, "startedAt" DESC);


--
-- Name: video_streams_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "video_streams_userId_idx" ON public.video_streams USING btree ("userId");


--
-- Name: vip_xp_ledger_source_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX vip_xp_ledger_source_idx ON public.vip_xp_ledger USING btree (source);


--
-- Name: vip_xp_ledger_userId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "vip_xp_ledger_userId_createdAt_idx" ON public.vip_xp_ledger USING btree ("userId", "createdAt");


--
-- Name: voice_sessions_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "voice_sessions_isActive_idx" ON public.voice_sessions USING btree ("isActive");


--
-- Name: voice_sessions_lastPing_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "voice_sessions_lastPing_idx" ON public.voice_sessions USING btree ("lastPing");


--
-- Name: voice_sessions_roomId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "voice_sessions_roomId_idx" ON public.voice_sessions USING btree ("roomId");


--
-- Name: voice_sessions_roomId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "voice_sessions_roomId_userId_key" ON public.voice_sessions USING btree ("roomId", "userId");


--
-- Name: voice_signals_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "voice_signals_createdAt_idx" ON public.voice_signals USING btree ("createdAt");


--
-- Name: voice_signals_processed_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX voice_signals_processed_idx ON public.voice_signals USING btree (processed);


--
-- Name: voice_signals_roomId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "voice_signals_roomId_idx" ON public.voice_signals USING btree ("roomId");


--
-- Name: voice_signals_toUserId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "voice_signals_toUserId_idx" ON public.voice_signals USING btree ("toUserId");


--
-- Name: weekly_dream_reports_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "weekly_dream_reports_userId_idx" ON public.weekly_dream_reports USING btree ("userId");


--
-- Name: weekly_dream_reports_userId_weekStart_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "weekly_dream_reports_userId_weekStart_key" ON public.weekly_dream_reports USING btree ("userId", "weekStart");


--
-- Name: weekly_tournament_entries_tournamentId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "weekly_tournament_entries_tournamentId_idx" ON public.weekly_tournament_entries USING btree ("tournamentId");


--
-- Name: weekly_tournament_entries_tournamentId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "weekly_tournament_entries_tournamentId_userId_key" ON public.weekly_tournament_entries USING btree ("tournamentId", "userId");


--
-- Name: weekly_tournament_entries_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "weekly_tournament_entries_userId_idx" ON public.weekly_tournament_entries USING btree ("userId");


--
-- Name: weekly_tournaments_category_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX weekly_tournaments_category_status_idx ON public.weekly_tournaments USING btree (category, status);


--
-- Name: weekly_tournaments_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX weekly_tournaments_status_idx ON public.weekly_tournaments USING btree (status);


--
-- Name: weekly_tournaments_weekStart_type_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "weekly_tournaments_weekStart_type_key" ON public.weekly_tournaments USING btree ("weekStart", type);


--
-- Name: withdrawal_requests_agencyId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "withdrawal_requests_agencyId_idx" ON public.withdrawal_requests USING btree ("agencyId");


--
-- Name: withdrawal_requests_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "withdrawal_requests_createdAt_idx" ON public.withdrawal_requests USING btree ("createdAt");


--
-- Name: withdrawal_requests_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX withdrawal_requests_status_idx ON public.withdrawal_requests USING btree (status);


--
-- Name: withdrawal_requests_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "withdrawal_requests_userId_idx" ON public.withdrawal_requests USING btree ("userId");


--
-- Name: accounts accounts_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT "accounts_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ad_placements ad_placements_adNetworkId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ad_placements
    ADD CONSTRAINT "ad_placements_adNetworkId_fkey" FOREIGN KEY ("adNetworkId") REFERENCES public.ad_networks(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: admin_user_actions admin_user_actions_targetUserId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_user_actions
    ADD CONSTRAINT "admin_user_actions_targetUserId_fkey" FOREIGN KEY ("targetUserId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: agency_commission_rules agency_commission_rules_agencyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_commission_rules
    ADD CONSTRAINT "agency_commission_rules_agencyId_fkey" FOREIGN KEY ("agencyId") REFERENCES public.agencies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: agency_earnings agency_earnings_agencyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_earnings
    ADD CONSTRAINT "agency_earnings_agencyId_fkey" FOREIGN KEY ("agencyId") REFERENCES public.agencies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: agency_leave_requests agency_leave_requests_agencyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_leave_requests
    ADD CONSTRAINT "agency_leave_requests_agencyId_fkey" FOREIGN KEY ("agencyId") REFERENCES public.agencies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: agency_leave_requests agency_leave_requests_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_leave_requests
    ADD CONSTRAINT "agency_leave_requests_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: agency_penalties agency_penalties_agencyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_penalties
    ADD CONSTRAINT "agency_penalties_agencyId_fkey" FOREIGN KEY ("agencyId") REFERENCES public.agencies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: agency_tasks agency_tasks_agencyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_tasks
    ADD CONSTRAINT "agency_tasks_agencyId_fkey" FOREIGN KEY ("agencyId") REFERENCES public.agencies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: agency_users agency_users_agencyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_users
    ADD CONSTRAINT "agency_users_agencyId_fkey" FOREIGN KEY ("agencyId") REFERENCES public.agencies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: agency_users agency_users_inviteCodeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_users
    ADD CONSTRAINT "agency_users_inviteCodeId_fkey" FOREIGN KEY ("inviteCodeId") REFERENCES public.invite_codes(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: agency_users agency_users_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_users
    ADD CONSTRAINT "agency_users_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: agency_wallet_transactions agency_wallet_transactions_agencyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_wallet_transactions
    ADD CONSTRAINT "agency_wallet_transactions_agencyId_fkey" FOREIGN KEY ("agencyId") REFERENCES public.agencies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: agency_wallets agency_wallets_agencyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_wallets
    ADD CONSTRAINT "agency_wallets_agencyId_fkey" FOREIGN KEY ("agencyId") REFERENCES public.agencies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: animation_assignments animation_assignments_animationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animation_assignments
    ADD CONSTRAINT "animation_assignments_animationId_fkey" FOREIGN KEY ("animationId") REFERENCES public.animations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: animation_assignments animation_assignments_assignedBy_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animation_assignments
    ADD CONSTRAINT "animation_assignments_assignedBy_fkey" FOREIGN KEY ("assignedBy") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: animation_assignments animation_assignments_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animation_assignments
    ADD CONSTRAINT "animation_assignments_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: animation_membership_defaults animation_membership_defaults_animationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animation_membership_defaults
    ADD CONSTRAINT "animation_membership_defaults_animationId_fkey" FOREIGN KEY ("animationId") REFERENCES public.animations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: animation_playback_logs animation_playback_logs_animationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animation_playback_logs
    ADD CONSTRAINT "animation_playback_logs_animationId_fkey" FOREIGN KEY ("animationId") REFERENCES public.animations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: animation_playback_logs animation_playback_logs_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animation_playback_logs
    ADD CONSTRAINT "animation_playback_logs_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: anonymous_fortunes anonymous_fortunes_anonymousUserId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anonymous_fortunes
    ADD CONSTRAINT "anonymous_fortunes_anonymousUserId_fkey" FOREIGN KEY ("anonymousUserId") REFERENCES public.anonymous_users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: bot_profiles bot_profiles_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_profiles
    ADD CONSTRAINT "bot_profiles_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: celebrity_follows celebrity_follows_celebrityId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.celebrity_follows
    ADD CONSTRAINT "celebrity_follows_celebrityId_fkey" FOREIGN KEY ("celebrityId") REFERENCES public.celebrities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: celebrity_follows celebrity_follows_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.celebrity_follows
    ADD CONSTRAINT "celebrity_follows_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: celebrity_post_comments celebrity_post_comments_postId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.celebrity_post_comments
    ADD CONSTRAINT "celebrity_post_comments_postId_fkey" FOREIGN KEY ("postId") REFERENCES public.celebrity_posts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: celebrity_post_comments celebrity_post_comments_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.celebrity_post_comments
    ADD CONSTRAINT "celebrity_post_comments_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: celebrity_post_likes celebrity_post_likes_postId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.celebrity_post_likes
    ADD CONSTRAINT "celebrity_post_likes_postId_fkey" FOREIGN KEY ("postId") REFERENCES public.celebrity_posts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: celebrity_post_likes celebrity_post_likes_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.celebrity_post_likes
    ADD CONSTRAINT "celebrity_post_likes_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: celebrity_posts celebrity_posts_celebrityId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.celebrity_posts
    ADD CONSTRAINT "celebrity_posts_celebrityId_fkey" FOREIGN KEY ("celebrityId") REFERENCES public.celebrities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cfc_contests cfc_contests_seasonId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cfc_contests
    ADD CONSTRAINT "cfc_contests_seasonId_fkey" FOREIGN KEY ("seasonId") REFERENCES public.cfc_seasons(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: cfc_participants cfc_participants_contestId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cfc_participants
    ADD CONSTRAINT "cfc_participants_contestId_fkey" FOREIGN KEY ("contestId") REFERENCES public.cfc_contests(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cfc_participants cfc_participants_teamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cfc_participants
    ADD CONSTRAINT "cfc_participants_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES public.cfc_teams(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: cfc_payment_requests cfc_payment_requests_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cfc_payment_requests
    ADD CONSTRAINT "cfc_payment_requests_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cfc_score_logs cfc_score_logs_contestId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cfc_score_logs
    ADD CONSTRAINT "cfc_score_logs_contestId_fkey" FOREIGN KEY ("contestId") REFERENCES public.cfc_contests(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cfc_teams cfc_teams_contestId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cfc_teams
    ADD CONSTRAINT "cfc_teams_contestId_fkey" FOREIGN KEY ("contestId") REFERENCES public.cfc_contests(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_bans chat_bans_bannedBy_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_bans
    ADD CONSTRAINT "chat_bans_bannedBy_fkey" FOREIGN KEY ("bannedBy") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_bans chat_bans_roomId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_bans
    ADD CONSTRAINT "chat_bans_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES public.chat_rooms(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_bans chat_bans_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_bans
    ADD CONSTRAINT "chat_bans_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_messages chat_messages_roomId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT "chat_messages_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES public.chat_rooms(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_messages chat_messages_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT "chat_messages_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_mutes chat_mutes_mutedBy_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_mutes
    ADD CONSTRAINT "chat_mutes_mutedBy_fkey" FOREIGN KEY ("mutedBy") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_mutes chat_mutes_roomId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_mutes
    ADD CONSTRAINT "chat_mutes_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES public.chat_rooms(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_mutes chat_mutes_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_mutes
    ADD CONSTRAINT "chat_mutes_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_presences chat_presences_roomId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_presences
    ADD CONSTRAINT "chat_presences_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES public.chat_rooms(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_presences chat_presences_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_presences
    ADD CONSTRAINT "chat_presences_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_room_gifts chat_room_gifts_giftTypeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_gifts
    ADD CONSTRAINT "chat_room_gifts_giftTypeId_fkey" FOREIGN KEY ("giftTypeId") REFERENCES public.gift_types(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: chat_room_gifts chat_room_gifts_recipientId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_gifts
    ADD CONSTRAINT "chat_room_gifts_recipientId_fkey" FOREIGN KEY ("recipientId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_room_gifts chat_room_gifts_roomId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_gifts
    ADD CONSTRAINT "chat_room_gifts_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES public.chat_rooms(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_room_gifts chat_room_gifts_senderId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_gifts
    ADD CONSTRAINT "chat_room_gifts_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_rooms chat_rooms_giftBeneficiaryId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_rooms
    ADD CONSTRAINT "chat_rooms_giftBeneficiaryId_fkey" FOREIGN KEY ("giftBeneficiaryId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: chat_rooms chat_rooms_ownerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_rooms
    ADD CONSTRAINT "chat_rooms_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: chat_user_roles chat_user_roles_roomId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_user_roles
    ADD CONSTRAINT "chat_user_roles_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES public.chat_rooms(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_user_roles chat_user_roles_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_user_roles
    ADD CONSTRAINT "chat_user_roles_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: conversations conversations_user1Id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT "conversations_user1Id_fkey" FOREIGN KEY ("user1Id") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: conversations conversations_user2Id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT "conversations_user2Id_fkey" FOREIGN KEY ("user2Id") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: daily_login_rewards daily_login_rewards_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_login_rewards
    ADD CONSTRAINT "daily_login_rewards_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: direct_messages direct_messages_receiverId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.direct_messages
    ADD CONSTRAINT "direct_messages_receiverId_fkey" FOREIGN KEY ("receiverId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: direct_messages direct_messages_senderId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.direct_messages
    ADD CONSTRAINT "direct_messages_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dream_comments dream_comments_dreamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_comments
    ADD CONSTRAINT "dream_comments_dreamId_fkey" FOREIGN KEY ("dreamId") REFERENCES public.dream_interpretations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dream_comments dream_comments_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_comments
    ADD CONSTRAINT "dream_comments_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dream_contest_entries dream_contest_entries_contestId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_contest_entries
    ADD CONSTRAINT "dream_contest_entries_contestId_fkey" FOREIGN KEY ("contestId") REFERENCES public.dream_contests(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dream_contest_entries dream_contest_entries_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_contest_entries
    ADD CONSTRAINT "dream_contest_entries_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dream_contest_votes dream_contest_votes_entryId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_contest_votes
    ADD CONSTRAINT "dream_contest_votes_entryId_fkey" FOREIGN KEY ("entryId") REFERENCES public.dream_contest_entries(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dream_contest_votes dream_contest_votes_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_contest_votes
    ADD CONSTRAINT "dream_contest_votes_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dream_diary_entries dream_diary_entries_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_diary_entries
    ADD CONSTRAINT "dream_diary_entries_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dream_favorites dream_favorites_dreamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_favorites
    ADD CONSTRAINT "dream_favorites_dreamId_fkey" FOREIGN KEY ("dreamId") REFERENCES public.dream_interpretations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dream_favorites dream_favorites_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_favorites
    ADD CONSTRAINT "dream_favorites_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dream_views dream_views_dreamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_views
    ADD CONSTRAINT "dream_views_dreamId_fkey" FOREIGN KEY ("dreamId") REFERENCES public.dream_interpretations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dream_views dream_views_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dream_views
    ADD CONSTRAINT "dream_views_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: email_verification_tokens email_verification_tokens_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_verification_tokens
    ADD CONSTRAINT "email_verification_tokens_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fan_club_members fan_club_members_fanClubId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fan_club_members
    ADD CONSTRAINT "fan_club_members_fanClubId_fkey" FOREIGN KEY ("fanClubId") REFERENCES public.fan_clubs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fan_club_members fan_club_members_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fan_club_members
    ADD CONSTRAINT "fan_club_members_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fan_club_poll_votes fan_club_poll_votes_pollId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fan_club_poll_votes
    ADD CONSTRAINT "fan_club_poll_votes_pollId_fkey" FOREIGN KEY ("pollId") REFERENCES public.fan_club_polls(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fan_club_poll_votes fan_club_poll_votes_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fan_club_poll_votes
    ADD CONSTRAINT "fan_club_poll_votes_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fan_club_polls fan_club_polls_fanClubId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fan_club_polls
    ADD CONSTRAINT "fan_club_polls_fanClubId_fkey" FOREIGN KEY ("fanClubId") REFERENCES public.fan_clubs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fan_club_polls fan_club_polls_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fan_club_polls
    ADD CONSTRAINT "fan_club_polls_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fan_club_post_likes fan_club_post_likes_postId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fan_club_post_likes
    ADD CONSTRAINT "fan_club_post_likes_postId_fkey" FOREIGN KEY ("postId") REFERENCES public.fan_club_posts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fan_club_post_likes fan_club_post_likes_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fan_club_post_likes
    ADD CONSTRAINT "fan_club_post_likes_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fan_club_posts fan_club_posts_fanClubId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fan_club_posts
    ADD CONSTRAINT "fan_club_posts_fanClubId_fkey" FOREIGN KEY ("fanClubId") REFERENCES public.fan_clubs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fan_club_posts fan_club_posts_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fan_club_posts
    ADD CONSTRAINT "fan_club_posts_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fan_clubs fan_clubs_celebrityId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fan_clubs
    ADD CONSTRAINT "fan_clubs_celebrityId_fkey" FOREIGN KEY ("celebrityId") REFERENCES public.celebrities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: follows follows_followerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows
    ADD CONSTRAINT "follows_followerId_fkey" FOREIGN KEY ("followerId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: follows follows_followingId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows
    ADD CONSTRAINT "follows_followingId_fkey" FOREIGN KEY ("followingId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fortunes fortunes_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fortunes
    ADD CONSTRAINT "fortunes_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: game_plays game_plays_gameId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_plays
    ADD CONSTRAINT "game_plays_gameId_fkey" FOREIGN KEY ("gameId") REFERENCES public.mini_games(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: game_room_chats game_room_chats_roomId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_room_chats
    ADD CONSTRAINT "game_room_chats_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES public.game_rooms(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: game_room_viewers game_room_viewers_roomId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_room_viewers
    ADD CONSTRAINT "game_room_viewers_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES public.game_rooms(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: gift_battle_participants gift_battle_participants_battleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gift_battle_participants
    ADD CONSTRAINT "gift_battle_participants_battleId_fkey" FOREIGN KEY ("battleId") REFERENCES public.gift_battles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: gift_box_entries gift_box_entries_boxId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gift_box_entries
    ADD CONSTRAINT "gift_box_entries_boxId_fkey" FOREIGN KEY ("boxId") REFERENCES public.gift_boxes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: gift_events gift_events_giftTypeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gift_events
    ADD CONSTRAINT "gift_events_giftTypeId_fkey" FOREIGN KEY ("giftTypeId") REFERENCES public.gift_types(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: gift_types gift_types_collectionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gift_types
    ADD CONSTRAINT "gift_types_collectionId_fkey" FOREIGN KEY ("collectionId") REFERENCES public.gift_collections(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: invite_codes invite_codes_agencyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invite_codes
    ADD CONSTRAINT "invite_codes_agencyId_fkey" FOREIGN KEY ("agencyId") REFERENCES public.agencies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: leaderboard_entries leaderboard_entries_periodId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leaderboard_entries
    ADD CONSTRAINT "leaderboard_entries_periodId_fkey" FOREIGN KEY ("periodId") REFERENCES public.leaderboard_periods(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: leaderboard_entries leaderboard_entries_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leaderboard_entries
    ADD CONSTRAINT "leaderboard_entries_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: leaderboard_periods leaderboard_periods_configId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leaderboard_periods
    ADD CONSTRAINT "leaderboard_periods_configId_fkey" FOREIGN KEY ("configId") REFERENCES public.leaderboard_configs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: leaderboard_rewards leaderboard_rewards_periodId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leaderboard_rewards
    ADD CONSTRAINT "leaderboard_rewards_periodId_fkey" FOREIGN KEY ("periodId") REFERENCES public.leaderboard_periods(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: leaderboard_rewards leaderboard_rewards_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leaderboard_rewards
    ADD CONSTRAINT "leaderboard_rewards_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: live_activities live_activities_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_activities
    ADD CONSTRAINT "live_activities_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: live_fortune_tellers live_fortune_tellers_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_fortune_tellers
    ADD CONSTRAINT "live_fortune_tellers_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: live_session_messages live_session_messages_sessionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_session_messages
    ADD CONSTRAINT "live_session_messages_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES public.live_sessions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: live_sessions live_sessions_tellerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_sessions
    ADD CONSTRAINT "live_sessions_tellerId_fkey" FOREIGN KEY ("tellerId") REFERENCES public.live_fortune_tellers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: live_sessions live_sessions_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_sessions
    ADD CONSTRAINT "live_sessions_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: live_teller_reviews live_teller_reviews_sessionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_teller_reviews
    ADD CONSTRAINT "live_teller_reviews_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES public.live_sessions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: live_teller_reviews live_teller_reviews_tellerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_teller_reviews
    ADD CONSTRAINT "live_teller_reviews_tellerId_fkey" FOREIGN KEY ("tellerId") REFERENCES public.live_fortune_tellers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: membership_grants membership_grants_giverId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membership_grants
    ADD CONSTRAINT "membership_grants_giverId_fkey" FOREIGN KEY ("giverId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: membership_grants membership_grants_receiverId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membership_grants
    ADD CONSTRAINT "membership_grants_receiverId_fkey" FOREIGN KEY ("receiverId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: membership_purchases membership_purchases_planId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membership_purchases
    ADD CONSTRAINT "membership_purchases_planId_fkey" FOREIGN KEY ("planId") REFERENCES public.membership_plans(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: membership_tier_features membership_tier_features_featureKey_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membership_tier_features
    ADD CONSTRAINT "membership_tier_features_featureKey_fkey" FOREIGN KEY ("featureKey") REFERENCES public.membership_features(key) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: membership_tier_features membership_tier_features_tierKey_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membership_tier_features
    ADD CONSTRAINT "membership_tier_features_tierKey_fkey" FOREIGN KEY ("tierKey") REFERENCES public.membership_tier_defs(key) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: message_requests message_requests_receiverId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_requests
    ADD CONSTRAINT "message_requests_receiverId_fkey" FOREIGN KEY ("receiverId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: message_requests message_requests_senderId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_requests
    ADD CONSTRAINT "message_requests_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: notifications notifications_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT "notifications_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: okey_match_players okey_match_players_matchId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.okey_match_players
    ADD CONSTRAINT "okey_match_players_matchId_fkey" FOREIGN KEY ("matchId") REFERENCES public.okey_matches(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: password_reset_tokens password_reset_tokens_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT "password_reset_tokens_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: payments payments_packageId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT "payments_packageId_fkey" FOREIGN KEY ("packageId") REFERENCES public.credit_packages(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: payments payments_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT "payments_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: phone_otps phone_otps_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.phone_otps
    ADD CONSTRAINT "phone_otps_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: pk_battle_participants pk_battle_participants_battleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pk_battle_participants
    ADD CONSTRAINT "pk_battle_participants_battleId_fkey" FOREIGN KEY ("battleId") REFERENCES public.pk_battles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: pk_gifts pk_gifts_battleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pk_gifts
    ADD CONSTRAINT "pk_gifts_battleId_fkey" FOREIGN KEY ("battleId") REFERENCES public.pk_battles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: pk_scores pk_scores_battleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pk_scores
    ADD CONSTRAINT "pk_scores_battleId_fkey" FOREIGN KEY ("battleId") REFERENCES public.pk_battles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: pk_seats pk_seats_matchId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pk_seats
    ADD CONSTRAINT "pk_seats_matchId_fkey" FOREIGN KEY ("matchId") REFERENCES public.pk_matches(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: profile_visits profile_visits_profileId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_visits
    ADD CONSTRAINT "profile_visits_profileId_fkey" FOREIGN KEY ("profileId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: profile_visits profile_visits_visitorId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_visits
    ADD CONSTRAINT "profile_visits_visitorId_fkey" FOREIGN KEY ("visitorId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: referral_commissions referral_commissions_earnerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_commissions
    ADD CONSTRAINT "referral_commissions_earnerId_fkey" FOREIGN KEY ("earnerId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: referral_commissions referral_commissions_sourceUserId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_commissions
    ADD CONSTRAINT "referral_commissions_sourceUserId_fkey" FOREIGN KEY ("sourceUserId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: referrals referrals_referredId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT "referrals_referredId_fkey" FOREIGN KEY ("referredId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: referrals referrals_referrerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT "referrals_referrerId_fkey" FOREIGN KEY ("referrerId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: refund_requests refund_requests_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refund_requests
    ADD CONSTRAINT "refund_requests_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_permissionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT "role_permissions_permissionId_fkey" FOREIGN KEY ("permissionId") REFERENCES public.permissions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_roleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT "role_permissions_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES public.roles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: room_revenue_logs room_revenue_logs_roomId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_revenue_logs
    ADD CONSTRAINT "room_revenue_logs_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES public.chat_rooms(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: room_signals room_signals_sessionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_signals
    ADD CONSTRAINT "room_signals_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES public.live_sessions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: sessions sessions_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT "sessions_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: short_video_comment_likes short_video_comment_likes_commentId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_comment_likes
    ADD CONSTRAINT "short_video_comment_likes_commentId_fkey" FOREIGN KEY ("commentId") REFERENCES public.short_video_comments(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: short_video_comment_likes short_video_comment_likes_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_comment_likes
    ADD CONSTRAINT "short_video_comment_likes_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: short_video_comments short_video_comments_parentId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_comments
    ADD CONSTRAINT "short_video_comments_parentId_fkey" FOREIGN KEY ("parentId") REFERENCES public.short_video_comments(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: short_video_comments short_video_comments_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_comments
    ADD CONSTRAINT "short_video_comments_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: short_video_comments short_video_comments_videoId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_comments
    ADD CONSTRAINT "short_video_comments_videoId_fkey" FOREIGN KEY ("videoId") REFERENCES public.short_videos(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: short_video_hashtags short_video_hashtags_hashtagId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_hashtags
    ADD CONSTRAINT "short_video_hashtags_hashtagId_fkey" FOREIGN KEY ("hashtagId") REFERENCES public.hashtags(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: short_video_hashtags short_video_hashtags_videoId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_hashtags
    ADD CONSTRAINT "short_video_hashtags_videoId_fkey" FOREIGN KEY ("videoId") REFERENCES public.short_videos(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: short_video_likes short_video_likes_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_likes
    ADD CONSTRAINT "short_video_likes_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: short_video_likes short_video_likes_videoId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_likes
    ADD CONSTRAINT "short_video_likes_videoId_fkey" FOREIGN KEY ("videoId") REFERENCES public.short_videos(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: short_video_mentions short_video_mentions_mentionedUserId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_mentions
    ADD CONSTRAINT "short_video_mentions_mentionedUserId_fkey" FOREIGN KEY ("mentionedUserId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: short_video_mentions short_video_mentions_videoId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_mentions
    ADD CONSTRAINT "short_video_mentions_videoId_fkey" FOREIGN KEY ("videoId") REFERENCES public.short_videos(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: short_video_saves short_video_saves_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_saves
    ADD CONSTRAINT "short_video_saves_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: short_video_saves short_video_saves_videoId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_saves
    ADD CONSTRAINT "short_video_saves_videoId_fkey" FOREIGN KEY ("videoId") REFERENCES public.short_videos(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: short_video_views short_video_views_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_views
    ADD CONSTRAINT "short_video_views_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: short_video_views short_video_views_videoId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_video_views
    ADD CONSTRAINT "short_video_views_videoId_fkey" FOREIGN KEY ("videoId") REFERENCES public.short_videos(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: short_videos short_videos_duetOfId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_videos
    ADD CONSTRAINT "short_videos_duetOfId_fkey" FOREIGN KEY ("duetOfId") REFERENCES public.short_videos(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: short_videos short_videos_musicId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_videos
    ADD CONSTRAINT "short_videos_musicId_fkey" FOREIGN KEY ("musicId") REFERENCES public.short_video_music(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: short_videos short_videos_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.short_videos
    ADD CONSTRAINT "short_videos_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: social_actions social_actions_actorId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_actions
    ADD CONSTRAINT "social_actions_actorId_fkey" FOREIGN KEY ("actorId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: social_actions social_actions_targetId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_actions
    ADD CONSTRAINT "social_actions_targetId_fkey" FOREIGN KEY ("targetId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: social_comments social_comments_postId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_comments
    ADD CONSTRAINT "social_comments_postId_fkey" FOREIGN KEY ("postId") REFERENCES public.social_posts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: social_comments social_comments_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_comments
    ADD CONSTRAINT "social_comments_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: social_likes social_likes_postId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_likes
    ADD CONSTRAINT "social_likes_postId_fkey" FOREIGN KEY ("postId") REFERENCES public.social_posts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: social_likes social_likes_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_likes
    ADD CONSTRAINT "social_likes_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: social_posts social_posts_fortuneId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_posts
    ADD CONSTRAINT "social_posts_fortuneId_fkey" FOREIGN KEY ("fortuneId") REFERENCES public.fortunes(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: social_posts social_posts_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_posts
    ADD CONSTRAINT "social_posts_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: sos_game_chats sos_game_chats_gameId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sos_game_chats
    ADD CONSTRAINT "sos_game_chats_gameId_fkey" FOREIGN KEY ("gameId") REFERENCES public.sos_games(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: sos_game_viewers sos_game_viewers_gameId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sos_game_viewers
    ADD CONSTRAINT "sos_game_viewers_gameId_fkey" FOREIGN KEY ("gameId") REFERENCES public.sos_games(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: stream_fortune_requests stream_fortune_requests_typeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_fortune_requests
    ADD CONSTRAINT "stream_fortune_requests_typeId_fkey" FOREIGN KEY ("typeId") REFERENCES public.fortune_request_types(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: stream_gifts stream_gifts_giftTypeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_gifts
    ADD CONSTRAINT "stream_gifts_giftTypeId_fkey" FOREIGN KEY ("giftTypeId") REFERENCES public.gift_types(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: stream_gifts stream_gifts_senderId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_gifts
    ADD CONSTRAINT "stream_gifts_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: stream_gifts stream_gifts_streamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_gifts
    ADD CONSTRAINT "stream_gifts_streamId_fkey" FOREIGN KEY ("streamId") REFERENCES public.video_streams(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: support_messages support_messages_ticketId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_messages
    ADD CONSTRAINT "support_messages_ticketId_fkey" FOREIGN KEY ("ticketId") REFERENCES public.support_tickets(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: team_members team_members_teamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_members
    ADD CONSTRAINT "team_members_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES public.teams(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: teller_chat_messages teller_chat_messages_chatSessionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teller_chat_messages
    ADD CONSTRAINT "teller_chat_messages_chatSessionId_fkey" FOREIGN KEY ("chatSessionId") REFERENCES public.teller_chat_sessions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: teller_chat_sessions teller_chat_sessions_liveSessionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teller_chat_sessions
    ADD CONSTRAINT "teller_chat_sessions_liveSessionId_fkey" FOREIGN KEY ("liveSessionId") REFERENCES public.live_sessions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: teller_warnings teller_warnings_tellerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teller_warnings
    ADD CONSTRAINT "teller_warnings_tellerId_fkey" FOREIGN KEY ("tellerId") REFERENCES public.live_fortune_tellers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tiktok_videos tiktok_videos_categoryId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tiktok_videos
    ADD CONSTRAINT "tiktok_videos_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES public.tiktok_categories(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: tournament_matches tournament_matches_roundId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournament_matches
    ADD CONSTRAINT "tournament_matches_roundId_fkey" FOREIGN KEY ("roundId") REFERENCES public.tournament_rounds(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tournament_rounds tournament_rounds_tournamentId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournament_rounds
    ADD CONSTRAINT "tournament_rounds_tournamentId_fkey" FOREIGN KEY ("tournamentId") REFERENCES public.weekly_tournaments(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: trend_videos trend_videos_categoryId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trend_videos
    ADD CONSTRAINT "trend_videos_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES public.trend_video_categories(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_blocks user_blocks_blockedId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT "user_blocks_blockedId_fkey" FOREIGN KEY ("blockedId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_blocks user_blocks_blockerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT "user_blocks_blockerId_fkey" FOREIGN KEY ("blockerId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_devices user_devices_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_devices
    ADD CONSTRAINT "user_devices_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_online_events user_online_events_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_online_events
    ADD CONSTRAINT "user_online_events_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_permission_overrides user_permission_overrides_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_permission_overrides
    ADD CONSTRAINT "user_permission_overrides_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_reports user_reports_reportedId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_reports
    ADD CONSTRAINT "user_reports_reportedId_fkey" FOREIGN KEY ("reportedId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_reports user_reports_reporterId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_reports
    ADD CONSTRAINT "user_reports_reporterId_fkey" FOREIGN KEY ("reporterId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_stories user_stories_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_stories
    ADD CONSTRAINT "user_stories_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_timeline_events user_timeline_events_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_timeline_events
    ADD CONSTRAINT "user_timeline_events_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_vip_preferences user_vip_preferences_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_vip_preferences
    ADD CONSTRAINT "user_vip_preferences_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_warnings user_warnings_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_warnings
    ADD CONSTRAINT "user_warnings_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: users users_adminAssignedFrameId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "users_adminAssignedFrameId_fkey" FOREIGN KEY ("adminAssignedFrameId") REFERENCES public.profile_frames(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: users users_profileFrameId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "users_profileFrameId_fkey" FOREIGN KEY ("profileFrameId") REFERENCES public.profile_frames(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: users users_referredById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "users_referredById_fkey" FOREIGN KEY ("referredById") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: video_stream_comments video_stream_comments_streamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_stream_comments
    ADD CONSTRAINT "video_stream_comments_streamId_fkey" FOREIGN KEY ("streamId") REFERENCES public.video_streams(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: video_stream_comments video_stream_comments_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_stream_comments
    ADD CONSTRAINT "video_stream_comments_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: video_stream_likes video_stream_likes_streamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_stream_likes
    ADD CONSTRAINT "video_stream_likes_streamId_fkey" FOREIGN KEY ("streamId") REFERENCES public.video_streams(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: video_stream_likes video_stream_likes_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_stream_likes
    ADD CONSTRAINT "video_stream_likes_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: video_stream_viewers video_stream_viewers_streamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_stream_viewers
    ADD CONSTRAINT "video_stream_viewers_streamId_fkey" FOREIGN KEY ("streamId") REFERENCES public.video_streams(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: video_streams video_streams_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_streams
    ADD CONSTRAINT "video_streams_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: vip_xp_ledger vip_xp_ledger_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vip_xp_ledger
    ADD CONSTRAINT "vip_xp_ledger_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: weekly_dream_reports weekly_dream_reports_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weekly_dream_reports
    ADD CONSTRAINT "weekly_dream_reports_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: weekly_tournament_entries weekly_tournament_entries_tournamentId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weekly_tournament_entries
    ADD CONSTRAINT "weekly_tournament_entries_tournamentId_fkey" FOREIGN KEY ("tournamentId") REFERENCES public.weekly_tournaments(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict lzD4s4usSR9D2o3dlL59I8JLnTd35JmNe5VtdYVfU1ovKZHY7a6C89wMFEC007I

