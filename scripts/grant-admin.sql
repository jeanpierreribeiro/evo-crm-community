INSERT INTO loans.system_authorities ("authUserId", "canCreate", "canDesignate", "active")
VALUES ('eab2e18f-0f79-41be-a905-213ecb556574', true, true, true)
ON CONFLICT ("authUserId") DO UPDATE
SET "canCreate" = true, "canDesignate" = true, "active" = true;
